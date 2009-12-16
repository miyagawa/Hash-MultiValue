package Hash::MultiValue;

use strict;
use 5.008_001;
our $VERSION = '0.01';

use Scalar::Util qw(refaddr);
my %obj;

sub new {
    my($class, @items) = @_;

    my(%hash, %mhash, @keys, %seen);
    while (@items) {
        my($key, $value) = splice @items, 0, 2;
        $hash{$key} = $value;
        push @{$mhash{$key}}, $value;
        push @keys, $key unless $seen{$key}++;
    }

    my $self = bless \%hash, $class;
    $obj{refaddr $self} = [ \%mhash, \@keys ];

    $self;
}

sub DESTROY {
    my $self = shift;
    delete $obj{refaddr $self};
}

sub obj {
    my $self = shift;
    $obj{refaddr $self};
}

sub get {
    my($self, $key) = @_;
    $self->{$key};
}

sub set {
    my($self, $key, $value) = @_;
    $self->{$key} = $value;

    my $obj = $self->obj;
    $obj->[0]->{$key} = $value;

    for my $k (@{$obj->[1]}) {
        return if $key eq $k;
    }
    push @{$obj->[1]}, $key;
}

sub remove {
    my($self, $key) = @_;
    delete $self->{$key};

    my $obj = $self->obj;
    delete $obj->[0]->{$key};

    my @new;
    for my $k (@{$obj->[1]}) {
        push @new, $k if $key ne $k;
    }
    $obj->[1] = \@new;
}

sub getall {
    my($self, $key) = @_;
    (@{$self->obj->[0]->{$key}});
}

sub keys {
    my $self = shift;
    @{$self->obj->[1]};
}

sub flatten {
    my $self = shift;
    my %mhash = %{$self->obj->[0]};

    my @list;
    while (my($key, $value) = each %mhash) {
        my @values = ref $value eq 'ARRAY' ? @$value : ($value);
        for my $v (@values) {
            push @list, $key, $v;
        }
    }

    return @list;
}

sub as_hash {
    my $self = shift;
    %{$self->obj->[0]}; # dclone?
}

sub as_hashref {
    my $self = shift;
    my %hash = $self->as_hash;
    \%hash;
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
