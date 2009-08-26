package CGI::Application::Plugin::PageLookup;

use warnings;
use strict;
use vars qw($VERSION @ISA  @EXPORT_OK);
use Carp;
require Exporter;
@ISA = qw(Exporter);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT_OK = qw(
    model
    model_load_tmpl
);

=head1 NAME

CGI::Application::Plugin::PageLookup - Installs a database backend into Titanium

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';

=head1 DESCRIPTION

See L<CGI::Application::PageLookup> for more information.

=head1 SYNOPSIS

    package MyCGIApp base qw(CGI::Application);
    use CGI::Application::Plugin::PageLookup qw(model model_load_tmpl);
    use CGI::Application::PageLookup;

    sub cgiapp_init {
        my $self = shift;
        # use the same args as DBI->connect();
        $self->dbh_config(......); # whatever arguments are appropriate

	$self->model(CGI::Application::PageLookup->new(dbh=>sub {return $self->dbh()}));

    }

    sub my_generic_runmode {
	my $self = shift;
	my $page_id = $self->param('PAGE_ID') or return $self->main_runmode();
	my $template_obj = $self->model_load_tmpl($page_id) or return $self->notfound($page_id);
	return $template_obj->output;
    }


=head1 EXPORT_OK

model
model_load_tmpl

=head1 FUNCTIONS

=head2 model

This returns cached model object. If there is no cached model it is taken from the second argument
which is then cached. Therefore this function is used to set the model.

=cut

sub model {
    my $self = shift;
    my $model = shift;
    unless(defined($self->{__cgi_application_plugin_pagelookup})) {
	$self->{__cgi_application_plugin_pagelookup} = $model || die  "no model defined";
    }
    return $self->{__cgi_application_plugin_pagelookup};
}

=head2 model_load_tmpl

    This takes a page id, lookups up the template and parameters and returns an enriched template. 
If there is no matching pageid in the database then the function will return an undef. It would do this
before attempting to call load_tmpl.

=cut

sub model_load_tmpl {
    my $self = shift;
    my $modelid = shift;
    my ($template, $params) = $self->model()->lookup($modelid);
    return undef unless ref($params) eq "HASH";
    my $templ_obj = $self->load_tmpl($template);

    # This function is defined in CGI::Application::Plugin::PageLookup::SiteStructure;
    # If it is available it will set the header expiry according to the changefreq parameter and delete it (as 
    # it will not be required elsewhere).
    $self->set_expiry($params) if $self->can('set_expiry');

    $templ_obj->param(%$params);
    return $templ_obj;
}

=head1 AUTHOR

Nicholas Bamber, C<< <nicholas at periapt.co.uk> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-cgi-application-plugin-model at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CGI-Application-Plugin-PageLookup>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc CGI::Application::Plugin::PageLookup


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=CGI-Application-Plugin-PageLookup>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/CGI-Application-Plugin-PageLookup>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/CGI-Application-Plugin-PageLookup>

=item * Search CPAN

L<http://search.cpan.org/dist/CGI-Application-Plugin-PageLookup/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 Nicholas Bamber, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of CGI::Application::Plugin::PageLookup
