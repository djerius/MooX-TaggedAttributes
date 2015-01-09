#!perl

use 5.10.0;

use Test::More;
use Test::Deep;

{
    package T1;

    use Moo::Role;
    use MooX::TaggedAttributes -tags => [ qw( tag1 tag2 ) ];


    has t1_1 => ( is => 'ro', default => 't1_1.v' );

}


{
    package C1;

    use Moo;
    T1->import;

    has c1_1 => (
        is      => 'rw',
        tag1    => 'c1_1.t1',
        tag2    => 'c1_1.t2',
        default => 'c1_1.v',
    );

    has c1_2 => (
        is      => 'rw',
        tag2    => 'c1_2.t2',
        default => 'c1_2.v',
    );

}

my $q = C1->new;

cmp_deeply(
    $q,
    methods(
        t1_1  => 't1_1.v',
        c1_1  => 'c1_1.v',
        c1_2  => 'c1_2.v',
        _tags => {
            tag1 => {
                c1_1 => 'c1_1.t1',
            },
            tag2 => {
                c1_1 => 'c1_1.t2',
                c1_2 => 'c1_2.t2',
            },
        },
    ),
);


done_testing;
