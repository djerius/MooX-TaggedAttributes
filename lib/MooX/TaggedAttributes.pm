# --8<--8<--8<--8<--
#
# Copyright (C) 2015 Smithsonian Astrophysical Observatory
#
# This file is part of MooX::TaggedAttributes
#
# MooX::TaggedAttributes is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or (at
# your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# -->8-->8-->8-->8--

package MooX::TaggedAttributes;

use 5.10.0;

use strict;
use warnings;

our $VERSION = '0.00';

use Carp;

use Moo::Role;

use Class::Method::Modifiers qw[ install_modifier ];

our %TAGSTORE;

my %ARGS = (
    -tags  => [],
);

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

sub _install_role_import {

    my $target = shift;

    ## no critic (ProhibitNoStrict)
    no strict 'refs';
    no warnings 'redefine';
    *{"${target}::import"} =
      sub {

        my $class = shift;
        my $target = caller;

        my %want = map { $_ => 1 } @_;

	my $want_role = ! $want{-norole};

        $want_role ||= ( exists $Moo::Role::INFO{$target}
              && !Moo::Role::does_role( $target, __PACKAGE__ ) );

        Moo::Role->apply_roles_to_package( $target, $class )
          if $want_role;

        _install_tags( $target, $TAGSTORE{$class} );
      };

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

    install_modifier(
        $target,
        after => has => sub {
            my ( $attrs, %attr ) = @_;

            my @attrs = ref $attrs ? @$attrs : $attrs;

            my $target = caller;

            my @tags = @{ $TAGSTORE{$target} };

            # we need to
            #  1) use the target package's around() function, and
            #  2) call it in that package's context.

	    ## no critic (ProhibitStringyEval)
            my $around = eval( "package $target; sub { goto &around }" );

            $around->(
                "_build__tags" => sub {
                    my $orig = shift;

                    my $tags = &$orig;

		    ## no critic (ProhibitAccessOfPrivateData)
                    for my $tag ( grep { exists $attr{$_} } @tags ) {
                        $tags->{$tag} //= {};
                        $tags->{$tag}{$_} = $attr{$tag} for @attrs;
                    }

                    return $tags;
                } );

        } );

}

use namespace::clean -except => qw( import );


has _tags => (
    is       => 'lazy',
    init_arg => undef,
    builder  => sub { {} },
);



1;

__END__

=head1 NAME

MooX::TaggedAttributes - Add a tag with an arbitrary value to a an attribute


=head1 SYNOPSIS

    # Create a Role used to apply the attributes
    package Tags;
    use Moo::Role;
    use MooX::TaggedAttributes -tags => [ qw( t1 t2 ) ];

    # Apply the role directly to a class
    package C1;
    use Tags;

    has c1 => ( is => 'ro', t1 => 1 );

    my $obj = C1->new;

    # get the value of the tag t1, applied to attribute a1
    $obj->_tags->{t1}{a1};

    # Apply the tags to a role
    package R1;
    use Tag1;

    has r1 => ( is => 'ro', t2 => 2 );

    # Use that role in a class
    package C2;
    use R1;

    has c2 => ( is => 'ro', t2 => sub { }  );

    # get the value of the tag t2, applied to attribute c2
    C2->new->_tags->{t2}{c2};

=head1 DESCRIPTION

This module attaches a tag-value pair to an attribute in a B<Moo>
class or role, and provides a interface to query which attributes have
which tags, and what the values are.

=head2 Tagging Attributes

=head3 Creating a Tag Role

To define a set of tags, create a special I<tag role>:

    package T;
    use Moo::Role;
    use MooX::TaggedAttributes -tags => [ qw( t1 t2 ) ];

    has attr => ( is => 'ro', t1 => 'boo' );

A tag role is a standard B<Moo::Role> with added machinery to track
attribute tags.  As shown, attributes may be tagged in the tag role
as well as in modules which consume it.

Tag roles may be consumed just as ordinary roles, but in order for
role consumers to have the ability to assign tags to attributes, they
need to be consumed with the Perl B<use> statement; consuming with the
B<with> statement will propagate attributes with existing tags, but
won't provide the ability to tag new attributes.

=head3 Using a Tag Role in a Role

To be able to tag attributes roles must consume a tagged role with the
Perl B<use> statement:

    package R2;
    use Moo::Role;
    use T;

    # the t1 tag is tracked
    has r2 => ( is => 'ro', t1 => 'foo' );

    package R3;
    use Moo::Role;
    use R3;

    # the t1 tag is tracked
    has r3 => ( is => 'ro', t1 => 'foo' );

The consuming role becomes a tag role, and can be used in the same
manner as the original tag role.

=head3 Combining Tag Roles

Combining tag roles is a simple as B<use>'ing them in the new role:

    package T12;
    use T1;
    use T2;

=head3 Using a Tag Role in a Class

Just as with roles, to provide the ability to tag attributes to a
class consuming a tagged role, use the B<use> statement:

    package C2;
    use Moo;
    use T;

    # the t1 tag is tracked
    has c2 => ( is => 'ro', t1 => 'foo' );

=head3 Class inheritance and Tag Roles

To be able to tag attributes when inheriting from a class with tagged attributes,
the tag class must be re-B<use>'ed with the C<-norule> flag:

    package C3;
    use Moo;
    use T;

    has c3 => ( is => 'ro', t1 => 'foo' );

    package C4;
    use Moo;
    extends 'C3';
    use T -norole;

    has c4 => ( is = 'ro', t1 => 'foo' );

If you forget the C<-norole> flag, none of the attribute tags will be
accessible.


=head2 Accessing tags

Objects are provided a B<_tags> method which returns a hash of hashes
keyed off of the tags and attribute names.  For example, for the
following code:

    package T;
    use Moo::Role;
    use MooX::TaggedAttributes -tags => [ qw( t1 t2 ) ];

    package C;
    use Moo;
    use T;

    has a => ( is => 'ro', t1 => 2 );
    has b => ( is => 'ro', t2 => 'foo' );

The tag structure returned by

    C->new->_tags

looks like

    { t1 => { a => 2 },
      t2 => { b => 'foo' },
    }

=head1 BUGS AND LIMITATIONS


No bugs have been reported.

Please report any bugs or feature requests to
C<bug-moox-taggedattributes@rt.cpan.org>, or through the web interface at
L<https://rt.cpan.org/Public/Dist/Display.html?Name=MooX-TaggedAttributes>.

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2015 The Smithsonian Astrophysical Observatory

MooX::TaggedAttributes is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or (at
your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

=head1 AUTHOR

Diab Jerius  E<lt>djerius@cpan.orgE<gt>


