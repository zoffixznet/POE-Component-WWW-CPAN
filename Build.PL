use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'POE::Component::WWW::CPAN',
    license             => 'perl',
    dist_author         => 'Zoffix Znet <zoffix@cpan.org>',
    dist_version_from   => 'lib/POE/Component/WWW/CPAN.pm',
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'POE'                                      => 0.9999,
        'POE::Component::NonBlockingWrapper::Base' => 0.002,
        'WWW::CPAN'                                => 0.011,
    },
    add_to_cleanup      => [ 'POE-Component-WWW-CPAN-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
