#!perl

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
        is   => 'rw',
        tag1 => 'c1_1.t1',
        tag2 => 'c1_1.t2',
    );

    has c1_2 => (
        is   => 'rw',
        tag2 => 'c1_2.t2',
    );

}

{
    package C2;

    use Moo;

    extends 'C1';

    has c2_1 => ( is => 'ro', default => 'c2_1.v' );
}

{
    my $q = C2->new();

    cmp_deeply(
        $q,
        methods(
            t1_1  => 't1_1.v',
            c2_1  => 'c2_1.v',
            _tags => {
                tag1 => {
                    c1_1 => 'c1_1.t1',
                },
                tag2 => {
                    c1_1 => 'c1_1.t2',
                    c1_2 => 'c1_2.t2',
                },
            }
        ),
    );



}

{
    package C3;

    use Moo;

    extends 'C2';
    T1->import;

    has c3_1 => (
        is      => 'rw',
        tag1    => 'c3_1.t1',
        default => 'c3_1.v',
    );

}

{
    my $q = C3->new();

    cmp_deeply(
        $q,
        methods(
            t1_1  => 't1_1.v',
            c2_1  => 'c2_1.v',
            c3_1  => 'c3_1.v',
            _tags => {
                tag1 => {
                    c1_1 => 'c1_1.t1',
                    c3_1 => 'c3_1.t1',
                },
                tag2 => {
                    c1_1 => 'c1_1.t2',
                    c1_2 => 'c1_2.t2',
                },
            },
        ),
    );



}

done_testing;
