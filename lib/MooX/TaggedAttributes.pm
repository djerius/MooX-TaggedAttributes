package MooX::TaggedAttributes;

# ABSTRACT: Add a tag with an arbitrary value to a an attribute

use strict;
use warnings;

our $VERSION = '0.06';

use Carp;
use MRO::Compat;

use Scalar::Util qw[ blessed ];
use Class::Method::Modifiers qw[ install_modifier ];

our %TAGSTORE;
our %TAGCACHE;

my %ARGS = ( -tags => [] );

sub import {

    my ( $class, @args ) = @_;
    my $target = caller;

    Moo::Role->apply_roles_to_package( $target, __PACKAGE__ );

    return unless @args;

    my %args = %ARGS;

    while ( @args ) {

        my $arg = shift @args;

        croak( "unknown argument to ", __PACKAGE__, ": $arg" )
          unless exists $ARGS{$arg};

        $args{$arg} = defined $ARGS{$arg} ? shift @args : 1;
    }

    $args{-tags} = [ $args{-tags} ]
      unless 'ARRAY' eq ref $args{-tags};

    _install_tags( $target, $args{-tags} )
      if @{ $args{-tags} };

    _install_role_import( $target );
}

# this needs to be accessible by tag role import() methods, but don't want it
# to pollute the namespace
our $_role_import = sub {
    my $class = shift;
    return unless Moo::Role->is_role( $class );

    my $target = caller;
    Moo::Role->apply_roles_to_package( $target, $class );
    _install_tags( $target, $TAGSTORE{$class} );
};


sub _install_role_import {

    my $target = shift;

    ## no critic (ProhibitStringyEval)

    croak( "error installing import routine into $target\n" )
      unless eval
      "package $target; sub import { goto \$MooX::TaggedAttributes::_role_import }; 1;";
}


sub _install_tags {

    my ( $target, $tags ) = @_;

    if ( $TAGSTORE{$target} ) {

        push @{ $TAGSTORE{$target} }, @$tags;

    }

    else {

        $TAGSTORE{$target} = [@$tags];
        _install_tag_handler( $target );
    }

}

sub _install_tag_handler {
    my $target = shift;

    # we need to
    #  1) use the target package's around() function, and
    #  2) call it in that package's context.

    # create a closure which knows about the target's around
    # so that if namespace::clean is called on the target class
    # we don't lose access to it.

    ## no critic (ProhibitStringyEval)
    my $around = eval( "package $target; sub { goto &around }" );

    install_modifier(
        $target,
        after => has => sub {
            my ( $attrs, %attr ) = @_;

            $attrs = ref $attrs ? $attrs : [$attrs];

            my @tags = @{ $TAGSTORE{$target} };

            $around->(
                "_tag_list" => sub {
                    my $orig = shift;

                    ## no critic (ProhibitAccessOfPrivateData)
                    return [
                        @{&$orig},
                        map { [ $_, $attrs, $attr{$_} ] }
                          grep { exists $attr{$_} } @tags,
                    ];

                } );

        } );
}

# Moo::Role won't compose anything before it was used into a consuming
# package. Don't want import to be consumed.
use Moo::Role;

use Sub::Name 'subname';

my $can = sub { ( shift )->next::can };

# this modifier is run once for each composition of a tag role into
# the class.  role composition is orthogonal to class inheritance, so we
# need to carefully handle both

# see http://www.nntp.perl.org/group/perl.moose/2015/01/msg287{6,7,8}.html,
# but note that djerius' published solution was incomplete.
around _tag_list => sub {


    # 1. call &$orig to handle tag role compositions into the current class

    # 2. call up the inheritance stack to handle parent class tag role compositions.

    my $orig    = shift;
    my $package = caller;

    # create the proper environment context for next::can
    my $next = ( subname "${package}::_tag_list" => $can )->( $_[0] );

    return [ @{&$orig}, $next ? @{&$next} : () ];
};


use namespace::clean -except => qw( import );

# _tags can't be lazy; we must resolve the tags and attributes at
# object creation time in case a role is modified after this object
# is created, as we scan both clsses and roles to gather the tags.
# classes should be immutable after the first instantiation
# of an object (but see RT#101631), but roles aren't.

# We also need to identify when a role has been added to an *object*
# which adds tagged attributes.  TODO: make this work.

sub _tag_list { [] }


# Build the tag cache.  Only update it if we're an object.  if the
# class hasn't yet been instantiated, it's still mutable, and we'd be
# caching prematurely.

sub _build_cache {

    my $class = shift;

    # returned cached tags if available.  Note that as of Moo v.1.006001
    # instantiated classes may still have attributes composed into them
    # (i.e., they're not fully immutable, see RT#101631), but that
    # is acknowledged as a bug, not a feature, so we don't support that.
    return $TAGCACHE{$class} if $TAGCACHE{$class};

    my %cache;

    for my $tuple ( @{ $class->_tag_list } ) {
        # my ( $tag, $attrs, $value ) = @$tuple;
        my $cache = ( $cache{ $tuple->[0] } ||= {} );
        $cache->{$_} = $tuple->[2] for @{ $tuple->[1] };
    }

    return \%cache;
}

has _tag_cache => (
    is       => 'ro',
    init_arg => undef,
    default  => sub {
        my $class = blessed( $_[0] );
        return $TAGCACHE{$class} ||= $class->_build_cache;
    }
);

sub _tags { blessed( $_[0] ) ? $_[0]->_tag_cache : $_[0]->_build_cache }

1;

# COPYRIGHT

__END__

=for stopwords instantiation use'ing

=head1 SYNOPSIS

# EXAMPLE: ./examples/synopsis/T1.pm

# EXAMPLE: ./examples/synopsis/C1.pm

# EXAMPLE: ./examples/synopsis/R1.pm

# EXAMPLE: ./examples/synopsis/C2.pm

# EXAMPLE: ./examples/synopsis/script.pl

=head1 DESCRIPTION

This module attaches a tag-value pair to an attribute in a B<Moo>
class or role, and provides a interface to query which attributes have
which tags, and what the values are.

=head2 Tagging Attributes

To define a set of tags, create a special I<tag role>:

# EXAMPLE: ./examples/description/T1.pm

If there's only one tag, it can be passed directly without being
wrapped in an array:

# EXAMPLE: ./examples/description/T2.pm

A tag role is a standard B<Moo::Role> with added machinery to track
attribute tags.  As shown, attributes may be tagged in the tag role
as well as in modules which consume it.

Tag roles may be consumed just as ordinary roles, but in order for
role consumers to have the ability to assign tags to attributes, they
need to be consumed with the Perl B<use> statement, not with the B<with> statement.

Consuming with the B<with> statement I<will> propagate attributes with
existing tags, but won't provide the ability to tag new attributes.

This is correct:

# EXAMPLE: ./examples/description/R2.pm

# EXAMPLE: ./examples/description/R3.pm

The same goes for classes:

# EXAMPLE: ./examples/description/C1.pm

Combining tag roles is as simple as B<use>'ing them in the new role:

# EXAMPLE: ./examples/description/T12.pm

# EXAMPLE: ./examples/description/C2.pm

=head2 Accessing tags

Classes and objects are provided a B<_tags> method which returns a
hash of hashes keyed off of the tags and attribute names.  For
example, for the following code:

# EXAMPLE: ./examples/accessing/T.pm

# EXAMPLE: ./examples/accessing/C.pm

The tag structure returned by  C<< C->_tags >>

# COMMAND: perl -Iexamples/accessing -MC -MData::Dump -e 'dd( C->_tags)'

and C<< C->new->_tags >>

# COMMAND: perl -Iexamples/accessing -MC -MData::Dump -E 'dd( C->new->_tags)'

are identical.

=head1 BUGS AND LIMITATIONS

=head2 Changes to an object after instantiation are not tracked.

If a role with tagged attributes is applied to an object, the
tags for those attributes are not visible.
