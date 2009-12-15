#!/usr/bin/perl
use strict;
use Benchmark;
use Hash::MultiValue;

my $how_many = shift || 100;

my @form = map { $_ => $_ % 5 == 0 ? [ rand 1000, rand 10000 ] :  rand 1000 } 1..$how_many;

timethese 0, {
    normal => sub {
        my %form = @form;
        my @k = keys %form;
        $form{14} = 1000;
        delete $form{14};
        my @values = @form{1..10};
    },
    multivalue => sub {
        my %form = Hash::MultiValue->new(@form);
        my @k = keys %form;
        $form{14} = 1000;
        delete $form{14};
        my @values = @form{1..10};
    },
};
