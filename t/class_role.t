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
    package R1;

    use Moo::Role;
    T1->import;

    has r1_1 => (
        is      => 'rw',
        tag1    => 'r1_1.t1',
        tag2    => 'r1_1.t2',
        default => 'r1_1.v'
    );

    has r1_2 => (
        is      => 'rw',
        tag1    => 'r1_2.t1',
        default => 'r1_2.v'
    );

}

{
    package C1;

    use Moo;

    with 'R1';

    has c1_1 => (
        is      => 'rw',
        default => 'c1_1.v'
    );
}

subtest 'class_role' => sub {

    my $q = C1->new();

    cmp_deeply(
        $q,
        methods(
            t1_1  => 't1_1.v',
            r1_1  => 'r1_1.v',
            r1_2  => 'r1_2.v',
            c1_1  => 'c1_1.v',
            _tags => {
                tag1 => {
                    r1_1 => 'r1_1.t1',
                    r1_2 => 'r1_2.t1',
                },
                tag2 => {
                    r1_1 => 'r1_1.t2',
                },
            },
        ),
    );
};

{
    package R2;
    use Moo::Role;

    with 'R1';

    # this tag shouldn't stick
    has r2_1 => ( is => 'ro', tag1 => 'rw_1.t1' );
}

{
    package C2;

    use Moo;

    with 'R2';

    has c2_1 => (
        is      => 'rw',
	tag1    => 'c2_1.v',  # shouldn't stick
        default => 'c2_1.v',
    );
}

subtest 'class_role_passthrough' => sub {

    my $q = C2->new();

    cmp_deeply(
        $q,
        methods(
            t1_1  => 't1_1.v',
            r1_1  => 'r1_1.v',
            r1_2  => 'r1_2.v',
            c2_1  => 'c2_1.v',
            _tags => {
                tag1 => {
                    r1_1 => 'r1_1.t1',
                    r1_2 => 'r1_2.t1',
                },
                tag2 => {
                    r1_1 => 'r1_1.t2',
                },
            },
        ),
    );
};


done_testing;
