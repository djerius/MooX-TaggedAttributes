#!perl

use Test::More;
use Test::Deep;

{
    package T1;

    use Moo::Role;
    use MooX::TaggedAttributes -tags => qw[ tag1 ];

    BEGIN {
	has t1_1 => ( is => 'ro', default => 't1_1.v' );
    }

}

{
    package T2;

    use Moo::Role;
    use MooX::TaggedAttributes -tags => qw[ tag2 ];

    BEGIN {
	has t2_1 => ( is => 'ro', default => 't2_1.v' );

    }

}


{
    package T12;

    use Moo::Role;

    use T1;
    use T2;

}

{
    package C1;

    use Moo;

    T12->import;

    has c1_1 => (
        is      => 'rw',
        tag1    => 'c1_1.t1',
        tag2    => 'c1_1.t2',
        default => 'c1_1.v',
    );

}

{
    my $q = C1->new();

    cmp_deeply(
        $q,
        methods(
            t1_1  => 't1_1.v',
            t2_1  => 't2_1.v',
            c1_1  => 'c1_1.v',
            _tags => {
                tag1 => {
                    c1_1 => 'c1_1.t1',
                },
                tag2 => {
                    c1_1 => 'c1_1.t2',
                },
            },
        ),
    );



}

done_testing;
