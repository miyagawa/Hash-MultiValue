#!/usr/bin/perl
use strict;
use Benchmark;
use Hash::MultiValue;

my @form = map { $_ => $_ % 5 == 0 ? [ rand 1000, rand 10000 ] :  rand 1000 } 1..200;

timethese 0, {
    normal => sub {
        my %form = @form;
        keys %form;
        $form{143} = 1000;
        delete $form{145};
        my @values = @form{1..100};
    },
    multivalue => sub {
        my %form = Hash::MultiValue->new(@form);
        keys %form;
        $form{143} = 1000;
        delete $form{145};
        my @values = @form{1..100};
    },
};



