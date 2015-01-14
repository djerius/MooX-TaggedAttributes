#!perl

use Test::More;
use Test::Deep;

{
    package T1;

    use Moo::Role;
    use MooX::TaggedAttributes -tags => [qw( t1 )];

    has t1_1 => ( is => 'ro', default => 't1_1.v' );

}

{
    package T2;

    use Moo::Role;
    use MooX::TaggedAttributes -tags => [qw( t2 )];

    has t2_1 => ( is => 'ro', default => 't2_1.v' );

}

{
    package C1;

    use Moo;
    T1->import;

    has c1_1 => (
        is      => 'rw',
        default => 'c1_1.v',
        t1      => 'c1_1.t1',
    );

    has c1_2 => ( is => 'rw', default => 'c1_2.v' );

}

subtest 'C1( T1 )' => sub {
    my $q = C1->new();

    cmp_deeply(
        $q,
        methods(
            t1_1  => 't1_1.v',
            c1_1  => 'c1_1.v',
            c1_2  => 'c1_2.v',
            _tags => {
                t1 => {
                    c1_1 => 'c1_1.t1',
                },
            }
        ),
    );



};

{
    package C2;

    use Moo;

    extends 'C1';

    has c2_1 => ( is => 'ro', default => 'c2_1.v' );
}

subtest 'C2( C1 )' => sub {
    my $q = C2->new();

    cmp_deeply(
        $q,
        methods(
            t1_1  => 't1_1.v',
            c1_1  => 'c1_1.v',
            c1_2  => 'c1_2.v',
            c2_1  => 'c2_1.v',
            _tags => {
                t1 => {
                    c1_1 => 'c1_1.t1',
                },
            }
        ),
    );



};

{
    package C3;

    use Moo;

    extends 'C2';
    T1->import;

    has c3_1 => (
        is      => 'rw',
        t1      => 'c3_1.t1',
        default => 'c3_1.v',
    );

}

subtest 'C3( C2, T1 )' => sub {
    my $q = C3->new();

    cmp_deeply(
        $q,
        methods(
            t1_1  => 't1_1.v',
            c1_1  => 'c1_1.v',
            c1_2  => 'c1_2.v',
            c2_1  => 'c2_1.v',
            c3_1  => 'c3_1.v',
            _tags => {
                t1 => {
                    c1_1 => 'c1_1.t1',
                    c3_1 => 'c3_1.t1',
                },
            },
        ),
    );

};


{
    package C4;

    use Moo;

    extends 'C3';
    T1->import;
    T2->import;

    has c4_1 => (
        is      => 'rw',
        t1      => 'c4_1.t1',
        t2      => 'c4_1.t2',
        default => 'c4_1.v',
    );

}

subtest 'C4( C3, T1, T2 )' => sub {
    my $q = C4->new();

    cmp_deeply(
        $q,
        methods(
            t1_1  => 't1_1.v',
            c1_1  => 'c1_1.v',
            c1_2  => 'c1_2.v',
            c2_1  => 'c2_1.v',
            c4_1  => 'c4_1.v',
            _tags => {
                t1 => {
                    c1_1 => 'c1_1.t1',
                    c3_1 => 'c3_1.t1',
                    c4_1 => 'c4_1.t1',
                },
                t2 => {
                    c4_1 => 'c4_1.t2',
                },
            },
        ),
    );

};


done_testing;
