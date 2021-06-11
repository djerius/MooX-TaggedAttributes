package MooX::TaggedAttributes::Cache;

# ABSTRACT: Extract information from a Tagged Attribute Cache

use 5.01001;

use strict;
use warnings;

use Hash::Util;

our $VERSION = '0.10';

use overload '%{}' => \&tag_hash, fallback => 1;

=overload %{}

The object may be treated as a hash reference. It will operate on the
reference returned by L</tag_hash>.  For example,

  keys %{ $cache };

is equivalent to

  keys %{ $cache->tag_hash };

=cut

=class_method new

  $cache = MooX::TaggedAttributes::Cache( $class );

Create a cache object for the C<$class>, which must have a C<_tag_list> method.

=cut

sub new {
    my ( $class, $target ) = @_;

    return bless { list => $target->_tag_list } , $class;
}

=method tag_hash

   $tags = $cache->tag_hash;

Returns a reference to a hash keyed off of the tags in the cache.  The
values are hashes which map attribute names to tag values.

B<Do Not Modify This Hash.>

=cut

sub tag_hash {

    my $self = shift;

    no overloading;

    return $self->{tag_hash} ||= do {
        my %tags;
        for my $tuple ( @{ $self->{list} } ) {
            # my ( $tag, $attrs, $value ) = @$tuple;
            my $tag = ( $tags{ $tuple->[0] } ||= {} );
            $tag->{$_} = $tuple->[2] for @{ $tuple->[1] };
        }
        Hash::Util::lock_hash( %tags );
        \%tags;
    };
}

=method attr_hash

   $tags = $cache->tag_hash;

Returns a reference to a hash keyed off of the attributes in the
cache.  The values are hashes which map tag names to tag values.

B<Do Not Modify This Hash.>

=cut

sub attr_hash {

    my $self = shift;

    no overloading;

    return $self->{attr_hash} ||= do {
        my %attrs;
        for my $tuple ( @{ $self->{list} } ) {
            # my ( $tag, $attrs, $value ) = @$tuple;
            ($attrs{$_} ||= {})->{$tuple->[0]} = $tuple->[2] for @{ $tuple->[1] };
        }
        Hash::Util::lock_hash( %attrs );
        \%attrs;
    };
}

=method tags

   # return all of the tags as an array reference
   $tags = $cache->tags;

   # return the tags for the specified attribute as an array reference
   $tags = $cache->tags( $attr );

Returns a reference to an array containing tags.

B<Do Not Modify This Array.>

=cut

sub tags {
    my ( $self, $attr ) = @_;

    no overloading;

    if ( ! defined $attr ) {
        return $self->{tags} ||= [ keys %{ $self->tag_hash } ];
    }

    return ($self->{attr} ||= {})->{$attr} ||= do {
        my $attrs = $self->attr_hash;
        [ keys %{ $attrs->{$attr} || {} } ];
     };
}

=method value

   $value = $cache->value( $attr, $tag );

Return the value of a tag for the given attribute.

=cut

sub value {
    my ( $self, $attr, $tag ) = @_;

    no autovivification;
    return $self->attr_hash->{$attr}{$tag};
}

# COPYRIGHT

__END__

=head1 SYNOPSIS

  $cache = MooX::TaggedAttributes::Cache->new( $class );

  $tags = $cache->tags;

=head1 DESCRIPTION

L<MooX::TaggedAttributes> caches attribute tags as objects of this class.
The user typically never instantiates objects of L<MooX::TaggedAttributes::Cache>.
Instead, they are returned by the L<_tags|MooX::TaggedAttributes/_tags> method added
to tagged classes, e.g.

  $cache = $class->_tags;
