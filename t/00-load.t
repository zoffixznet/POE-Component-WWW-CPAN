#!/usr/bin/env perl

use Test::More tests => 4;

BEGIN {
    use_ok('POE');
    use_ok('POE::Component::NonBlockingWrapper::Base');
    use_ok('WWW::CPAN');
	use_ok( 'POE::Component::WWW::CPAN' );
}

diag( "Testing POE::Component::WWW::CPAN $POE::Component::WWW::CPAN::VERSION, Perl $], $^X" );
