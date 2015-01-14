#!perl

use Test::More;
use Test::Deep;

{
    package T1;

    use Moo::Role;
    use MooX::TaggedAttributes -tags => [qw( t1 )];

    has t1_1 => (
        is      => 'ro',
        default => 't1_1.v',
    );

}

{
    package T2;

    use Moo::Role;
    use MooX::TaggedAttributes -tags => [qw( t2 )];

    has t2_1 => (
        is      => 'ro',
        default => 't2_1.v',
    );

}

{
    package R1;

    use Moo::Role;
    T1->import;

    has r1_1 => (
        is      => 'ro',
        t1      => 'r1_1.t1',
        default => 'r1_1.v',
    );

}


{
    package R2;

    use Moo::Role;
    T2->import;

    has r2_1 => (
        is      => 'ro',
        t2      => 'r2_1.t2',
        default => 'r2_1.v',
    );

}

{
    package R3;

    use Moo;
    T1->import;
    T2->import;

    has r3_1 => (
        is      => 'ro',
        t1      => 'r3_1.t1',
        t2      => 'r3_1.t2',
        default => 'r3_1.v',
    );

}


{
    package B0;

    use Moo;

    has b1_1 => (
        is      => 'rw',
        default => 'b1_1.v',
    );

}

subtest 'B0' => sub {

    cmp_deeply(
        B0->new,
        methods(
            b1_1 => 'b1_1.v',
        ),
    );

};

{
    package B1;

    use Moo;
    T1->import;

    has b1_1 => (
        is      => 'rw',
        default => 'b1_1.v',
        t1      => 'b1_1.t1',
    );

}

subtest 'B1( T1 )' => sub {

    cmp_deeply(
        B1->new,
        methods(
            b1_1  => 'b1_1.v',
            _tags => {
                t1 => {
                    b1_1 => 'b1_1.t1',
                },
            },
        ),
    );

};

{
    package B2;

    use Moo;
    T2->import;

    has b2_1 => (
        is      => 'rw',
        default => 'b2_1.v',
        t2      => 'b2_1.t2',
    );

}

subtest 'B2( T2 )' => sub {

    cmp_deeply(
        B2->new,
        methods(
            b2_1  => 'b2_1.v',
            _tags => {
                t2 => {
                    b2_1 => 'b2_1.t2',
                },
            },
        ),
    );

};

{
    package B3;

    use Moo;
    T2->import;
    T1->import;

    has b3_1 => (
        is      => 'rw',
        default => 'b3_1.v',
        t1      => 'b3_1.t1',
        t2      => 'b3_1.t2',
    );

}

subtest 'B3( T1, T2 )' => sub {

    cmp_deeply(
        B3->new,
        methods(
            b3_1  => 'b3_1.v',
            _tags => {
                t1 => {
                    b3_1 => 'b3_1.t1',
                },
                t2 => {
                    b3_1 => 'b3_1.t2',
                },
            },
        ),
    );

};

{
    package C1;

    use Moo;
    extends 'B1';

    has c1_1 => (
        is      => 'ro',
        default => 'c1_1.v',
    );

}

subtest 'C1( B1 )' => sub {

    cmp_deeply(
        C1->new,
        methods(
            b1_1  => 'b1_1.v',
            c1_1  => 'c1_1.v',
            _tags => {
                t1 => {
                    b1_1 => 'b1_1.t1',
                },
            },
        ),
    );

};

{
    package C2;

    use Moo;
    extends 'B2';

    has c2_1 => (
        is      => 'ro',
        default => 'c2_1.v',
    );

}

subtest 'C2( B2 )' => sub {

    cmp_deeply(
        C2->new,
        methods(
            b2_1  => 'b2_1.v',
            c2_1  => 'c2_1.v',
            _tags => {
                t2 => {
                    b2_1 => 'b2_1.t2',
                },
            },
        ),
    );

};

{
    package C3;

    use Moo;
    extends 'B3';

    has c3_1 => (
        is      => 'ro',
        default => 'c3_1.v',
    );

}

subtest 'C3( B3 )' => sub {

    cmp_deeply(
        C3->new,
        methods(
            b3_1  => 'b3_1.v',
            c3_1  => 'c3_1.v',
            _tags => {
                t1 => {
                    b3_1 => 'b3_1.t1',
                },
                t2 => {
                    b3_1 => 'b3_1.t2',
                },
            },
        ),
    );

};

{
    package C4;

    use Moo;
    extends 'B1';

    with 'R1';

    has c4_1 => (
        is      => 'ro',
        default => 'c4_1.v',
    );

}

subtest 'C4( B1, R1 )' => sub {

    cmp_deeply(
        C4->new,
        methods(
            b1_1  => 'b1_1.v',
            c4_1  => 'c4_1.v',
            r1_1  => 'r1_1.v',
            _tags => {
                t1 => {
                    b1_1 => 'b1_1.t1',
                    r1_1 => 'r1_1.t1',
                },
            },
        ),
    );

};

{
    package C5;

    use Moo;
    extends 'C4';

    R1->import;
    R2->import;

    has c5_1 => (
        is      => 'ro',
        default => 'c5_1.v',
        t1      => 'c5_1.t1',
        t2      => 'c5_1.t2',
    );

}

subtest 'C5( C4, R1, R2 )' => sub {

    cmp_deeply(
        C5->new,
        methods(
            b1_1  => 'b1_1.v',
            c4_1  => 'c4_1.v',
            c5_1  => 'c5_1.v',
            r1_1  => 'r1_1.v',
            r2_1  => 'r2_1.v',
            _tags => {
                t1 => {
                    b1_1 => 'b1_1.t1',
                    c5_1 => 'c5_1.t1',
                    r1_1 => 'r1_1.t1',
                },
                t2 => {
                    c5_1 => 'c5_1.t2',
                    r2_1 => 'r2_1.t2',
                },
            },
        ),
    );

};

{
    package C6;

    use Moo;
    extends 'B1';

    with 'R1';
    with 'R2';

}

subtest 'C6( B1, R1, R2 )' => sub {

    cmp_deeply(
        C6->new,
        methods(
            b1_1  => 'b1_1.v',
            r1_1  => 'r1_1.v',
            r2_1  => 'r2_1.v',
            _tags => {
                t1 => {
                    b1_1 => 'b1_1.t1',
                    r1_1 => 'r1_1.t1',
                },
                t2 => {
                    r2_1 => 'r2_1.t2',
                },
            },
        ),
    );

};

{
    package C7;

    use Moo;
    extends 'B2';

    with 'R1';
    with 'R2';

}

subtest 'C7( B2, R1, R2 )' => sub {

    cmp_deeply(
        C7->new,
        methods(
            b2_1  => 'b2_1.v',
            r1_1  => 'r1_1.v',
            r2_1  => 'r2_1.v',
            _tags => {
                t1 => {
                    r1_1 => 'r1_1.t1',
                },
                t2 => {
                    b2_1 => 'b2_1.t2',
                    r2_1 => 'r2_1.t2',
                },
            },
        ),
    );

};

{
    package C8;

    use Moo;
    extends 'B3';

    with 'R1';
    with 'R2';

}

subtest 'C8( B3, R1, R2 )' => sub {

    cmp_deeply(
        C8->new,
        methods(
            b3_1  => 'b3_1.v',
            r1_1  => 'r1_1.v',
            r2_1  => 'r2_1.v',
            _tags => {
                t1 => {
                    b3_1 => 'b3_1.t1',
                    r1_1 => 'r1_1.t1',
                },
                t2 => {
                    b3_1 => 'b3_1.t2',
                    r2_1 => 'r2_1.t2',
                },
            },
        ),
    );

};

done_testing;
