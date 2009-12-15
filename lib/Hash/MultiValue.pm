package Hash::MultiValue;

use strict;
use 5.008_001;
our $VERSION = '0.01';

use overload '%{}' => \&as_hashref, fallback => 1;

sub new {
    my($class, @items) = @_;
    bless \@items, $class;
}

sub iter {
    my($self, $cb) = @_;
    my @copy = @$self;
    while (@copy) {
        my($key, $value) = splice @copy, 0, 2;
        $cb->($key, $value);
    }
}

sub get {
    my($self, $key) = @_;
    my $value;
    $self->iter(sub { $value = $_[1] if $_[0] eq $key });
    return $value;
}

sub getall {
    my($self, $key) = @_;
    my @values;
    $self->iter(sub { push @values, $_[1] if $_[0] eq $key });
    return @values;
}

sub keys {
    my $self = shift;
    my(@keys, %seen);
    $self->iter(sub { push @keys, $_[0] unless $seen{$_[0]}++ });
    return @keys;
}

sub as_hash {
    my $self = shift;
    my %hash;
    $self->iter(sub {
        my($key, $value) = @_;
        unless (exists $hash{$key}) {
            $hash{$key} = Hash::MultiValue::Value->new;
        }
        $hash{$key}->push($value);
    });

    return %hash;
}

sub as_hashref {
    my $self = shift;
    my %hash = $self->as_hash;
    \%hash;
}

package Hash::MultiValue::Value;
use overload '@{}' => \&array, '""' => \&value, '0+' => \&value, fallback => 1;

sub ref {
    my $self = shift;
    @{$self->{value}} > 1 ? 'ARRAY' : undef;
}

sub new {
    my $class = shift;
    bless { value => [] }, $class;
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

  keys %$hash; # ('foo', 'bar') but not guaranteed to be ordered. See ->keys OO API

  # get a plain hash
  %hash = $hash->as_hash;
  %hash = %$hash; # same!

  # Object Oriented
  my $v = $hash->get('foo'); # 'b'
  my @v = $hash->getall('foo'); # ('a', 'b')

  $hash->keys; # ('foo', 'bar') guaranteed to be ordered

=head1 DESCRIPTION

Hash::MultiValue is an object that behaves like a hash reference that
contains multiple values per key, inspired by MultiDict of WebOb.

It doesn't use C<tie> but instead blessed objects with C<overload> for
stringification and array derefernces etc.

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
