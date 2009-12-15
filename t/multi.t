use strict;
use Test::More;
use Hash::MultiValue;

my $hash = Hash::MultiValue->new(
    foo => 'a',
    foo => 'b',
    bar => 'baz',
    baz => 33,
);

is "$hash->{foo}", 'b';
is ref $hash->{foo}, '';
my @foo = $hash->getall('foo');
is_deeply \@foo, [ 'a', 'b' ];
is_deeply [ sort keys %$hash ], [ 'bar', 'baz', 'foo' ];
is_deeply [ $hash->keys ], [ 'foo', 'bar', 'baz' ];
is $hash->{baz} + 2, 35;

done_testing;
