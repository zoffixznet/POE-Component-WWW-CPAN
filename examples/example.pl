#!/usr/bin/env perl

use strict;
use warnings;

use lib '../lib';

use POE qw/Component::WWW::CPAN/;

my $poco = POE::Component::WWW::CPAN->spawn;

POE::Session->create(
    package_states => [
        main => [ qw/_start results/ ],
    ],
);

$poe_kernel->run;

sub _start {
    $poco->search({
            event => 'results',
            query => 'App::ZofCMS',
            n => 2,
        }
    );
}

sub results {
    use Data::Dumper;
    print "Done\n";
    print Dumper $_[ARG0];
    $poco->shutdown;
}