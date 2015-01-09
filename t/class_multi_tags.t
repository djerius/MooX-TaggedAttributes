#!perl

use Test::More;
use Test::Deep;

{
    package T1;

    use Moo::Role;
    use MooX::TaggedAttributes -tags => qw( tag1 );

    BEGIN {
        has t1_1 => ( is => 'ro', default => 't1_1.v' );
    }

}

{
    package T2;

    use Moo::Role;
    use MooX::TaggedAttributes -tags => qw( tag2 );

    BEGIN {
        has t2_1 => ( is => 'ro', default => 't2_1.v' );
    }

}

{
    package C1;

    use Moo;
    T1->import;

    has c1_1 => (
        is      => 'rw',
        tag1    => 'c1_1.t1',
        default => 'c1_1.v',
    );


}

{
    my $q = C1->new();

    cmp_deeply(
        $q,
        methods(
            t1_1  => 't1_1.v',
            c1_1  => 'c1_1.v',
            _tags => {
                tag1 => {
                    c1_1 => 'c1_1.t1',
                },
            }
        ),
    );



}
{
    package C2;

    use Moo;

    extends 'C1';

    T2->import( '-norole' );

    has c2_1 => (
        is      => 'ro',
        tag2    => 'c2_1.t2',
        default => 'c2_1.v',
    );
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
                    c2_1 => 'c2_1.t2',
                },
            }
        ),
    );



}

{
    package T3;

    use Moo::Role;

    use T1;
    use T2;

}


{
    package C3;

    use Moo;

    extends 'C2';
    T3->import;

    has c3_1 => (
        is      => 'rw',
        tag1    => 'c3_1.t1',
        tag2    => 'c3_1.t2',
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
                    c2_1 => 'c2_1.t2',
                    c3_1 => 'c3_1.t2',
                },
            },
        ),
    );



}

done_testing;
