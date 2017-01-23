use strict;
use Test::More;
use Hash::MultiValue;
use Storable qw'nstore retrieve';

my $hash = Hash::MultiValue->from_mixed(
    {
        foo => [ 'a', 'b' ],
        bar => 'baz',
        baz => 33,
    }
);

nstore $hash, "serialized";

is( $hash->flatten, 8 );

is( retrieve( q-serialized- )->flatten, 8 );

my $quote = "'";
$quote = '"' if $^O eq 'MSWin32';
my $keys = `perl -MStorable -MHash::MultiValue -e $quote print scalar Storable::retrieve(q-serialized-)->flatten $quote `;
unlink "serialized";

is( $keys, 8 );

done_testing;
