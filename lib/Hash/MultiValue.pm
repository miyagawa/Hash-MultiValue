package Hash::MultiValue;

use strict;
use 5.008_001;
our $VERSION = '0.01';

use Scalar::Util qw(refaddr);
my %items;

sub new {
    my $class = shift;

    my %hash = @_; # yay, this should keep the last value

    my $self = bless \%hash, $class;
    $items{refaddr $self} = \@_;

    $self;
}

sub DESTROY {
    my $self = shift;
    delete $items{refaddr $self};
}

sub _iter {
    my($self, $cb) = @_;
    my $items = $items{refaddr $self};
    my $i;
    while ($i < $#$items) {
        $cb->( @{$items}[ $i, $i+1 ] );
        $i += 2;
    }
}

sub get {
    my($self, $key) = @_;
    $self->{$key};
}

sub get_all {
    my($self, $key) = @_;
    my @values;
    $self->_iter(sub { push @values, $_[1] if $_[0] eq $key });
    (@values);
}

sub add {
    my $self = shift;
    my $key = shift;
    $self->{$key} = $_[-1];
    push @{$items{refaddr $self}}, $key, @_;
}

sub remove {
    my($self, $key) = @_;
    delete $self->{$key};

    my @new;
    $self->_iter(sub { push @new, @_ if $_[0] ne $key });
    $items{refaddr $self} = \@new;
}

sub keys {
    my $self = shift;
    my(@keys, %seen);
    $self->_iter(sub { push @keys, $_[0] unless $seen{$_[0]}++ });
    (@keys);
}

sub flatten {
    my $self = shift;
    @{$items{refaddr $self}};
}

sub as_hash {
    my $self = shift;

    my %hash;
    $self->_iter(sub {
        my($key, $value) = @_;
        if (exists $hash{$key}) {
            if (ref $hash{$key} eq 'ARRAY') {
                push @{$hash{$key}}, $value;
            } else {
                $hash{$key} = [ $hash{$key}, $value ];
            }
        } else {
            $hash{$key} = $value;
        }
    });

    %hash;
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
  my @foo = $hash->get_all('foo'); # ('a', 'b')

  keys %$hash; # ('foo', 'bar') not guaranteed to be ordered
  $hash->keys; # ('foo', 'bar') guaranteed to be ordered

  # get a plain hash where values may or may not be an array ref
  %hash = $hash->as_hash;

  # get a pair so you can pass it to new()
  @pairs = $hash->flatten; # ('foo' => 'a', 'foo' => 'b', 'bar' => 'baz')

=head1 DESCRIPTION

Hash::MultiValue is an object (and a plain hash reference) that may
contain multiple values per key, inspired by MultiDict of WebOb.

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

This module provides a solution to this by making it behave like a
single value hash reference, but also has an API to get multiple
values on demand, explicitly.

=head1 HOW THIS WORKS

The object returned by C<new> is a blessed hash reference that
contains the last entry of the same key if there are multiple values,
but it also keeps the original pair state in the object tracker (a.k.a
inside out objects) and allows you to access the original pairs and
multiple values via the method calls, such as C<get_all> or C<flatten>.

This module does not use C<tie> or L<overload> and is quite fast.

Yes, there is L<Tie::Hash::MultiValue> and this module tries to solve
exactly the same problem, but using a different implementation.

=head1 UPDATING CONTENTS

When you update the content of the hash, B<DO NOT UPDATE> using the
hash reference interface: this won't write through to the tracking
object.

  my $hash = Hash::MultiValue->new(...);

  # WRONG
  $hash->{foo} = 'bar';
  delete $hash->{foo};

  # Correct
  $hash->add(foo => 'bar');
  $hash->remove('foo');

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

Thanks to Michael Peters for the suggestion to use inside-out objects
instead of tie and to Aristotle Pegaltzis for various performance fixes.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<http://pythonpaste.org/webob/#multidict> L<Tie::Hash::MultiValue>

=cut
