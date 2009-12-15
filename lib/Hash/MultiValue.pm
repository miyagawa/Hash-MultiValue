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
    @{$self->{$key}};
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
        my @values = ref $value eq 'ARRAY' ? @$value : ($value);
        push @{$hash{$key}}, @values;
        push @keys, $key unless $seen{$key}++;
    }

    bless [ \%hash, \@keys ], $class;
}

sub FETCH {
    my($self, $key) = @_;
    my $v = $self->[0]->{$key};
    return Hash::MultiValue::Value->new(@$v);
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

package Hash::MultiValue::Value;
use overload '@{}' => \&array, '""' => \&value, '0+' => \&value, fallback => 1;

sub ref {
    my $self = shift;
    @{$self->{value}} > 1 ? 'ARRAY' : undef;
}

sub new {
    my $class = shift;
    bless { value => [@_] }, $class;
}

sub push {
    my($self, $v) = @_;
    push @{$self->{value}}, $v;
}

sub value {
    my $self = shift;
    $self->{value}->[-1];
}

sub array {
    my $self = shift;
    \@{$self->{value}};
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

  print $hash->{foo};        # 'b' (the last entry)
  my @foo = @{$hash->{foo}}; # ('a', 'b')

  # Object Oriented get
  my $foo = $hash->get('foo'); # always 'b', independent of context
  my @foo = $hash->getall('foo'); # ('a', 'b')

  keys %$hash; # ('foo', 'bar') not guaranteed to be ordered
  $hash->keys; # ('foo', 'bar') guaranteed to be ordered

  # get a plain hash. values are all array references
  %hash = $hash->as_hash;

  # get a pair so you can pass it to new()
  @pairs = $hash->flatten; # ('foo' => 'a', 'foo' => 'b', 'bar' => 'baz')

=head1 DESCRIPTION

Hash::MultiValue is an object that behaves like a hash reference that
contains multiple values per key, inspired by MultiDict of WebOb.

It uses C<tie> to reflect writes to a hash, and also a blessed objects
with C<overload> to return values so it does the right thing in
stringification and array derefernces context.

=head1 NOTES ABOUT ref

If your existing application uses C<ref> to check if the hash value is multiple, i.e.:

  my $form = $req->parameters;
  my @v = ref $form->{v} eq 'ARRAY' ? @{$form->{v}} : ($form->{v});

The C<ref> call would return the string I<Hash::MultiValue::Value> by
default, so your code always assumes that it is a single value
element. To avoid this, you can use L<UNIVERSAL::ref> module, and then
if C<< $form->{v} >> has multiple values C<ref> would return C<ARRAY>
instead, and your code would continue working.

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<http://pythonpaste.org/webob/#multidict> L<Tie::Hash::MultiValue>

=cut
