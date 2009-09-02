package CGI::Application::Plugin::PageLookup::Loop;

use warnings;
use strict;

=head1 NAME

CGI::Application::Plugin::PageLookup::Loop - Manage list structures in a website

=head1 VERSION

Version 1.0

=cut

our $VERSION = '1.0';
our $AUTOLOAD;

=head1 DESCRIPTION

This module manages the instantiation of list style template parameters across a website;
for example TMPL_LOOP in L<HTML::Template>, though one must use L<HTML::Template::Pluggable> for it to
work. For example a menu is typically implemented in HTML as <ul>....</ul>. Using this module
the menu can be instantiated from the database and the same data used to instantiate a human-readable
sitemap page. On the other hand the staff page will have list data that is only required on that page.
This module depends on L<CGI::Application::Plugin::PageLookup::Loop>.

=head1 SYNOPSIS

In the template you might define a menu as follows (with some CSS and javascript to make it look nice):

    <ul>
    <TMPL_LOOP NAME="loop.menu">
	<li>
		<a href="<TMPL_VAR NAME="lang">/<TMPL_VAR NAME="href1">"><TMPL_VAR NAME="atitle1"></a>
		<TMPL_IF NAME="submenu1">
		<ul>
		<TMPL_LOOP NAME="submenu1">
			<li>
				<a href="<TMPL_VAR NAME="lang">/<TMPL_VAR NAME="href2">"><TMPL_VAR NAME="atitle2"></a>
				<TMPL_IF NAME="submenu2">
				<ul>
				<TMPL_LOOP NAME="submenu2">
				<li>
					<a href="<TMPL_VAR NAME="lang">/<TMPL_VAR NAME="href3">"><TMPL_VAR NAME="atitle3"></a>
				</li>
				</TMPL_LOOP>
				</ul>
				</TMPL_IF>
			</li>
		</TMPL_LOOP>
		</ul>	
		</TMPL_IF>
	</li>
    </TMPL_LOOP>
    </ul>

and the intention is that this should be the same on all English pages, the same on all Vietnamese pages etc etc.
You must register the "loop" parameter as a CGI::Application::Plugin::PageLookup::Loop object as follows:

    use CGI::Application;
    use CGI::Application::Plugin::PageLookup qw(:all);
    use CGI::Application::Plugin::PageLookup::Loop;
    use HTML::Template::Pluggable;
    use HTML::Template::Plugin::Dot;

    sub cgiapp_init {
        my $self = shift;

        # pagelookup depends CGI::Application::DBH;
        $self->dbh_config(......); # whatever arguments are appropriate

        $self->html_tmpl_class('HTML::Template::Pluggable');

        $self->pagelookup_config(

                # load smart dot-notation objects
                objects =>
                (
                        # Register the 'values' parameter
                        loop => 'CGI::Application::Plugin::PageLookup::Loop,
		}
	);
    }


    ...

The astute reader will notice that the above will only work if you set the 'global_vars' to true. After that all that remains is to populate the cgiapp_values table with the appropriate values. Notice that the code does
not need to know what comes after the dot in the templates. So if you want to set "values.hope" to "disappointment" in all English
pages you would run

	INSERT (lang, param, value) VALUES ('en', 'hope', 'disappointment')

On the other hand if you wanted set "values.hope" to "a glimmer of light" on page 7 but "disappointment" everywhere else, then you would
run

	INSERT (lang, param, value) VALUES ('en', 'hope', 'disappointment')
	INSERT (lang, internalId, param, value) VALUES ('en', 7, 'hope', 'a glimmer of light')
	

=head1 DATABASE

This module depends on only one extra table: cgiapp_loops. The lang and internalId columns join against
the cgiapp_table. However the internalId column can null, making the parameter available to all pages
in the same language. The key is formed by all of the columns except for the value.

Table: cgiapp_values
Field       |Type                                                               |Null|Key |Default|Extra|
--------------------------------------------------------------------------------------------------------
lang        |varchar(2)                                                         |NO  |    |NULL   |     |
internalId  |unsigned numeric(10,0)                                             |YES |    |NULL   |     |
loopName    |varchar(20)							|NO  |    |NULL	  |     |
lineage	    |varchar(255)							|NO  |    |       |     |
rank	    |unsigned numeric(2,0)						|NO  |	  |0      |     |
param       |varchar(20)                                                        |NO  |    |NULL   |     |
value       |text								|NO  |    |NULL   |     |

The loopName is the parameter name of the TMPL_LOOP structure. The rank indicates which iteration of the loop
this row is instantiating. The lineage is a comma separated list of ranks so that we know what part of a nested
loop structure this row instantiates. For a top-level parameter this will always be the empty string.

=head1 FUNCTIONS

=head2 new

A constructor folowing the requirements set out in L<CGI::Application::Plugin::PageLookup>.

=cut

sub new {
	my $class = shift;
	my $self = {};
	$self->{cgiapp} = shift;
	$self->{page_id} = shift;
	$self->{template} = shift;
	$self->{hash_ref} = shift;
	my %args = @_;
	$self->{config} = \%args;
	bless $self, $class;
	return $self;
}

=head2 can

We need to autoload methods so that the template writer can use variables without needing to know
where the variables  will be used. Thus 'can' must return a true value in all cases to avoid breaking
L<HTML::Template::Plugin::Dot>. Also 'can' is supposed to either return undef or a CODE ref. This seems the cleanest
way of meeting all requirements.

=cut

sub can {
	my $self = shift;
	my $param = shift;
	return sub {
	  my $self = shift;
          my $prefix = $self->{cgiapp}->pagelookup_prefix(%{$self->{config}});
          my $page_id = $self->{page_id};
          my $dbh = $self->{cgiapp}->dbh;
          my @sql = (
                "SELECT v.value FROM ${prefix}values v, ${prefix}pages p WHERE v.internalId = p.internalId AND v.param = '$param' AND v.lang = p.lang AND p.pageId = '$page_id'",
                "SELECT v.value FROM ${prefix}values v, ${prefix}pages p WHERE v.internalId IS NULL AND v.param = '$param' AND v.lang = p.lang AND p.pageId = '$page_id'");
          foreach my $s (@sql) {
                my $sth = $dbh->prepare($s) || croak $dbh->errstr;
                $sth->execute || croak $dbh->errstr;
                my $hash_ref = $sth->fetchrow_hashref;
                if ($hash_ref) {
                        $sth->finish;
                        return $hash_ref->{value};
                }
                croak $sth->errstr if $sth->err;
                $sth->finish;
          }
          return undef;

	};
}

=head2 AUTOLOAD 

We need to autoload methods so that the template writer can use variables without needing to know
where the variables  will be used.

=cut

sub AUTOLOAD {
	my $self = shift;
	my @method = split /::/, $AUTOLOAD;
	my $param = pop @method;
	my $c = $self->can($param);
	return &$c($self) if $c;
	return undef;
}

=head2 DESTRROY

We have to define DESTROY, because an autoloaded version would be bad.

=cut

sub DESTROY {
}

=head1 AUTHOR

Nicholas Bamber, C<< <nicholas at periapt.co.uk> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-cgi-application-plugin-pagelookup at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CGI-Application-Plugin-PageLookup>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head2 AUTOLOAD

AUTOLOAD is quite a fraught subject. There is probably no perfect solution. See http://www.perlmonks.org/?node_id=342804 for a sample of the issues.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc CGI::Application::Plugin::PageLookup::Loop


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

Copyright 2009 Nicholas Bamber.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of CGI::Application::Plugin::PageLookup::Loop
