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
my @foo = @{$hash->{foo}};
is_deeply \@foo, [ 'a', 'b' ];
is_deeply [ sort keys %$hash ], [ 'bar', 'baz', 'foo' ];
is_deeply [ $hash->keys ], [ 'foo', 'bar', 'baz' ];
is $hash->{baz} + 2, 35;

is $hash->{baz}->ref, undef;
is $hash->{foo}->ref, 'ARRAY';

done_testing;
