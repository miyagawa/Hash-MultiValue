use strict;
use Test::More;
use Hash::MultiValue;

my $hash = Hash::MultiValue->new(
    foo => 'a',
    foo => 'b',
    bar => 'baz',
    baz => 33,
);

my %foo = $hash->as_hash;
is scalar keys %foo, 3;
is ref $foo{foo}, 'ARRAY';
is $foo{bar}, 'baz';

done_testing;
