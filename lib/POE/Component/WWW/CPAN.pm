package POE::Component::WWW::CPAN;

use warnings;
use strict;

our $VERSION = '0.0101';

use POE;
use base 'POE::Component::NonBlockingWrapper::Base';
use WWW::CPAN;

sub _methods_define {
    return (
        search => '_wheel_entry',
    );
}

sub search {
    $poe_kernel->post( shift->{session_id} => search => @_ );
}

sub _prepare_wheel {
    shift->{cpan} = WWW::CPAN->new;
}

sub _process_request {
    my ( $self, $req_ref ) = @_;
    my $method = delete $req_ref->{method} || 'search';

    my %valid_keys = map { $_ => 1 }
        qw/ dist  author  version  query  mode  n  s/;

    my %method_args;
    $method_args{ $_ } = delete $req_ref->{ $_ }
        for grep { exists $valid_keys{ $_ } } keys %$req_ref;


    $req_ref->{result} = $self->{cpan}->$method( \%method_args );
}

1;
__END__

=head1 NAME

POE::Component::WWW::CPAN - non-blocking wrapper around WWW::CPAN

=head1 SYNOPSIS

    use strict;
    use warnings;

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
                query => 'App::ZofCMS::Plugin',
                n => 100
            }
        );
    }

    sub results {
        use Data::Dumper;
        print Dumper $_[ARG0]->{result};
        $poco->shutdown;
    }

Using event based interface is also possible of course.

=head1 DESCRIPTION

The module is a non-blocking wrapper around L<WWW::CPAN>
which provides interface to L<http://search.cpan.org/> searching
capabilities.

=head1 CONSTRUCTOR

=head2 C<spawn>

    my $poco = POE::Component::WWW::CPAN->spawn;

    POE::Component::WWW::CPAN->spawn(
        alias => 'cpan',
        options => {
            debug => 1,
            trace => 1,
            # POE::Session arguments for the component
        },
        debug => 1, # output some debug info
    );

The C<spawn> method returns a
POE::Component::WWW::CPAN object. It takes a few arguments,
I<all of which are optional>. The possible arguments are as follows:

=head3 C<alias>

    ->spawn( alias => 'cpan' );

B<Optional>. Specifies a POE Kernel alias for the component.

=head3 C<options>

    ->spawn(
        options => {
            trace => 1,
            default => 1,
        },
    );

B<Optional>.
A hashref of POE Session options to pass to the component's session.

=head3 C<debug>

    ->spawn(
        debug => 1
    );

When set to a true value turns on output of debug messages. B<Defaults to:>
C<0>.

=head1 METHODS

=head2 C<search>

    $poco->search( {
            event       => 'event_for_output',
            query       => 'WWW::CPAN',
            _blah       => 'pooh!',
            session     => 'other',
        }
    );

Takes a hashref as an argument, does not return a sensible return value.
See C<search> event's description for more information.

=head2 C<session_id>

    my $poco_id = $poco->session_id;

Takes no arguments. Returns component's session ID.

=head2 C<shutdown>

    $poco->shutdown;

Takes no arguments. Shuts down the component.

=head1 ACCEPTED EVENTS

=head2 C<search>

    $poe_kernel->post( cpan => search => {
            event       => 'event_for_output',
            query       => 'WWW::CPAN',
            _blah       => 'pooh!',
            session     => 'other',
        }
    );

Instructs the component to make a search on Lhttp://search.cpan.org/>.
Takes a hashref as an
argument, the possible keys/value of that hashref are as follows:

=head3 C<event>

    { event => 'results_event', }

B<Mandatory>. Specifies the name of the event to emit when results are
ready. See OUTPUT section for more information.

=head3 C<method>

    { method => 'fetch_distmeta' }

    { method => 'search' }

B<Optional>. Specifies which method to call on L<WWW::CPAN> object.
Possible values are C<fetch_distmeta>, C<search> and C<query> where C<query>
is just an alias to C<search>.
B<Defaults to:> C<search>.

=head3 C<query>

    { query => 'WWW::CPAN' }

B<Mandatory> unless C<method> argument (see above) is set to
C<fetch_distmeta> in which case argument C<query> is not used.
Specifies the term for which you are searching.

=head3 C<mode>

    { query => 'WWW::CPAN', mode => 'all' }

    { query => 'WWW::CPAN', mode => 'module' }

    { query => 'WWW::CPAN', mode => 'dist' }

    { query => 'WWW::CPAN', mode => 'author' }

B<Optional>. Valid when C<method> argument it set to either C<query> or
C<search> (the default). Takes a scalar as an argument which can be either
one of C<all>, C<dist>, C<module> or C<author>. Specifies what should
your query search - same as on L<http://search.cpan.org/>. B<Defaults to:>
C<all>

=head3 C<n>

    { query => 'WWW::CPAN', n => 50 }

B<Optional>. Takes an integer between C<1> and C<100>. Specifies how
many results you wish to have per "page" (see C<s> option below).
Values larger than 100 will get reset to 100. B<Defaults to:> C<10>

=head3 C<s>

    { query => 'WWW::CPAN', s => 10 }

B<Optional>. Takes a positive integer as a value. Specifies the page
number you wish to access - same as on L<http://search.cpan.org>. In
other words, if your C<n> (see above) is set to C<10>, and your C<s>
argument is set to 2, you will get results 10 to 20. B<Defaults to:> C<1>

=head3 C<session>

    { session => 'other' }

    { session => $other_session_reference }

    { session => $other_session_ID }

B<Optional>. Takes either an alias, reference or an ID of an alternative
session to send output to.

=head3 user defined

    {
        _user    => 'random',
        _another => 'more',
    }

B<Optional>. Any keys starting with C<_> (underscore) will not affect the
component and will be passed back in the result intact.

=head2 C<shutdown>

    $poe_kernel->post( cpan => 'shutdown' );

Takes no arguments. Tells the component to shut itself down.

=head1 OUTPUT

    $VAR1 = {
        'result' => {
            'matches' => '12',
            'start' => '1',
            'module' => [
                {
                    'link' => 'http://search.cpan.org/author/ZOFFIX/App-ZofCMS-0.0103/lib/App/ZofCMS.pm',
                    'version' => '0.0103',
                    'name' => 'App::ZofCMS',
                    'released' => '27th July 2008',
                    'author' => {
                        'link' => 'http://search.cpan.org/~zoffix/'
                     },
                     'description' => 'web framework and templating system for small-medium sites. '
                },
                {
                    'link' => 'http://search.cpan.org/author/ZOFFIX/App-ZofCMS-Plugin-Tagged-0.0201/lib/App/ZofCMS/Plugin/Tagged.pm',
                    'name' => 'App::ZofCMS::Plugin::Tagged',
                    'released' => '28th July 2008',
                    'author' => {
                        'link' => 'http://search.cpan.org/~zoffix/'
                    },
                    'description' => 'ZofCMS plugin to fill templates with data from query, template variables and configuration using <TAGS> '
                }
            ]
        },
        '_blah' => 'foo',
    };

The event handler set up to handle the event which you've specified in
the C<event> argument to C<search()> method/event will recieve input
in the C<$_[ARG0]> in a form of a hashref. The possible keys/value of
that hashref are as follows:

=head2 user defined

    { '_blah' => 'foos' }

Any arguments beginning with C<_> (underscore) passed into the C<search()>
event/method will be present intact in the result.

=head1 SEE ALSO

L<POE>, L<WWW::CPAN>

=head1 AUTHOR

Zoffix Znet, C<< <zoffix at cpan.org> >>
(L<http://zoffix.com>, L<http://haslayout.net>)

=head1 BUGS

Please report any bugs or feature requests to C<bug-poe-component-www-cpan at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=POE-Component-WWW-CPAN>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc POE::Component::WWW::CPAN

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=POE-Component-WWW-CPAN>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/POE-Component-WWW-CPAN>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/POE-Component-WWW-CPAN>

=item * Search CPAN

L<http://search.cpan.org/dist/POE-Component-WWW-CPAN>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2008 Zoffix Znet, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

