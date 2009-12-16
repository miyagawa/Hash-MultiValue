package Hash::MultiValue;

use strict;
use 5.008_001;
our $VERSION = '0.01';

sub new {
    my($class, @items) = @_;
    tie my %hash, 'Hash::MultiValue::Tied', @items;
    bless \%hash, $class;
}

sub get {
    my($self, $key) = @_;
    scalar $self->{$key};
}

sub set {
    my($self, $key, $value) = @_;
    $self->{$key} = $value;
}

sub getall {
    my($self, $key) = @_;
    tied(%$self)->getall($key);
}

sub keys {
    my $self = shift;
    tied(%$self)->keys;
}

sub flatten {
    my $self = shift;
    tied(%$self)->flatten;
}

sub as_hash {
    my $self = shift;
    tied(%$self)->as_hash;
}

sub as_hashref {
    my $self = shift;
    my %hash = $self->as_hash;
    \%hash;
}

package Hash::MultiValue::Tied;
use Tie::Hash;
use base qw( Tie::ExtraHash );

sub TIEHASH {
    my($class, @items) = @_;

    my(%hash, @keys, %seen);
    while (@items) {
        my($key, $value) = splice @items, 0, 2;
        push @{$hash{$key}}, $value;
        push @keys, $key unless $seen{$key}++;
    }

    bless [ \%hash, \@keys ], $class;
}

sub FETCH {
    my($self, $key) = @_;
    my $v = $self->[0]->{$key};
    return $v->[-1];
}

sub getall {
    my($self, $key) = @_;
    my $v = $self->[0]->{$key};
    @$v;
}

sub STORE {
    my($self, $key, $value) = @_;
    my @values = ref $value eq 'ARRAY' ? @$value : ($value);
    $self->[0]->{$key} = \@values;

    for my $k (@{$self->[1]}) {
        return if $key eq $k;
    }
    push @{$self->[1]}, $key;
}

sub DELETE {
    my($self, $key) = @_;
    delete $self->[0]->{$key};

    my @new;
    for my $k (@{$self->[1]}) {
        push @new, $k if $key ne $k;
    }
    $self->[1] = \@new;
}

sub keys {
    my $self = shift;
    @{$self->[1]};
}

sub as_hash {
    my $self = shift;
    %{$self->[0]};
}

sub flatten {
    my $self = shift;

    my @list;
    while (my($key, $value) = each %{$self->[0]}) {
        my @values = ref $value eq 'ARRAY' ? @$value : ($value);
        for my $v (@values) {
            push @list, $key, $v;
        }
    }

    return @list;
}

1;
__END__

=encoding utf-8

=for stopwords

=head1 NAME

Hash::MultiValue - Store multiple values per key

=head1 SYNOPSIS

  use Hash::MultiValue;

  my $hash = Hash::MultiValue->new(
      foo => 'a',
      foo => 'b',
      bar => 'baz',
  );

  # $hash is an object, but can be used as a hashref and DWIMs!

  my $foo = $hash->{foo};         # 'b' (the last entry)
  my $foo = $hash->get('foo');    # 'b' (always, regardless of context)
  my @foo = $hash->getall('foo'); # ('a', 'b')

  keys %$hash; # ('foo', 'bar') not guaranteed to be ordered
  $hash->keys; # ('foo', 'bar') guaranteed to be ordered

  # get a plain hash. values are all array references
  %hash = $hash->as_hash;

  # get a pair so you can pass it to new()
  @pairs = $hash->flatten; # ('foo' => 'a', 'foo' => 'b', 'bar' => 'baz')

=head1 DESCRIPTION

Hash::MultiValue is an object that behaves like a hash reference that
may contain multiple values per key, inspired by MultiDict of WebOb.

It uses C<tie> to make the object behaves also like a hash reference.

=head1 WHY THIS MODULE

In a typical web application, the request parameters (a.k.a CGI
parameters) can be single value or multi values. Using CGI.pm style
C<param> is one way to deal with this problem (and it is good), but
there's another approach to convert parameters into a hash reference,
like Catalyst's C<< $c->req->parameters >> does, and it B<sucks>.

Why? Because the value could be just a scalar if there is one value
and an array ref if there are multiple, depending on I<user input>
rather than I<how you code it>. So your code should always be like
this to be defensive:

  my $p = $c->req->parameters;
  my @maybe_multi = ref $p->{m} eq 'ARRAY' ? @{$p->{m}} : ($p->{m});
  my $must_single = ref $p->{m} eq 'ARRAY' ? $p->{m}->[0] : $p->{m};

Otherwise you'll get a random runtime exception of I<Can't use string
as an ARRAY ref> or get stringified array I<ARRAY(0xXXXXXXXXX)> as a
string, I<depending on user input> and which is miserable and
insecure.

This module provides a solution to this by returning a tied hash which
always behaves like an element with a single hash, but as well as an
explicit API call like C<get> and C<getall> to return single or
multiple values.

Yes, there is L<Tie::Hash::MultiValue> and this module tries to solve
exactly the same problem, but in a slightly different API.

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<http://pythonpaste.org/webob/#multidict> L<Tie::Hash::MultiValue>

=cut
