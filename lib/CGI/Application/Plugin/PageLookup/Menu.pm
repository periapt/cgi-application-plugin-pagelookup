package CGI::Application::Plugin::PageLookup::Menu;

use warnings;
use strict;
use Carp;

=head1 NAME

CGI::Application::Plugin::PageLookup::Menu - Support for consistent menus across a multilanguage website

=head1 VERSION

Version 1.0

=cut

our $VERSION = '1.0';
our $AUTOLOAD;

=head1 DESCRIPTION

The L<CGI::Application::Plugin::PageLookup::Loop> module can be used to create a database driven menu 
and similarly data driven site map page. However the Loop module can only translate into other languages
if the URLs are kept the same apart from a language identifier. This means that the website
would have  search engine friendly in only one language.
The L<CGI::Application::Plugin::PageLookup::Href> module
could be used to create a static menu and site map that is automatically translated into various languages
with search engine friendly URLs.
However they cannot be combined as you cannot pass through first the Loop and then the Href.
What this module offers is a specialized variant of the Loop smart object that does combine these features.
This module depends on L<CGI::Application::Plugin::PageLookup>.

=head1 SYNOPSIS

In the template you might define a menu as follows (with some CSS and javascript to make it look nice):

    <ul>
    <TMPL_LOOP NAME="loop.menu">
	<li>
		<a href="<TMPL_VAR NAME="lang">/<TMPL_VAR NAME="this.href1">"><TMPL_VAR NAME="this.atitle1"></a>
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
The use of "this." below the top levels is dictated by L<HTML::Template::Plugin::Dot> which also optionally allows
renaming of this implicit variable. You must register the "loop" parameter as a CGI::Application::Plugin::PageLookup::Menu object as follows:

    use CGI::Application;
    use CGI::Application::Plugin::PageLookup qw(:all);
    use CGI::Application::Plugin::PageLookup::Menu;
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
                {
                        # Register the 'values' parameter
                        loop => 'CGI::Application::Plugin::PageLookup::Menu',
		},

		# Processing of the 'lang' parameter inside a loop requires global_vars = 1 inside the template infrastructure
		template_params => {global_vars => 1}

	);
    }


    ...

The astute reader will notice that the above will only work if you set the 'global_vars' to true. After that all that remains is to populate
the cgiapp_loops table with the appropriate values. To fill the above menu you might run the following SQL:

	INSERT INTO cgiapp_loops (lang, loopName, lineage, rank, param, value) VALUES ('en', 'menu', '', 0, 'href1', '')
	INSERT INTO cgiapp_loops (lang, loopName, lineage, rank, param, value) VALUES ('en', 'menu', '', 0, 'atitle1', 'Home page')
	INSERT INTO cgiapp_loops (lang, loopName, lineage, rank, param, value) VALUES ('en', 'menu', '', 1, 'href1', 'aboutus')
	INSERT INTO cgiapp_loops (lang, loopName, lineage, rank, param, value) VALUES ('en', 'menu', '', 1, 'atitle1', 'About us')
	INSERT INTO cgiapp_loops (lang, loopName, lineage, rank, param, value) VALUES ('en', 'menu', '', 2, 'href1', 'products')
	INSERT INTO cgiapp_loops (lang, loopName, lineage, rank, param, value) VALUES ('en', 'menu', '', 2, 'atitle1', 'Our products')
	INSERT INTO cgiapp_loops (lang, loopName, lineage, rank, param, value) VALUES ('en', 'menu', '', 3, 'href1', 'contactus')
	INSERT INTO cgiapp_loops (lang, loopName, lineage, rank, param, value) VALUES ('en', 'menu', '', 3, 'atitle1', 'Contact us')
	INSERT INTO cgiapp_loops (lang, loopName, lineage, rank, param, value) VALUES ('en', 'menu', '', 4, 'href1', 'sitemap')
	INSERT INTO cgiapp_loops (lang, loopName, lineage, rank, param, value) VALUES ('en', 'menu', '', 4, 'atitle1', 'Sitemap')

Now suppose that you need to describe the products in more detail. Then you might add the following rows:

	INSERT INTO cgiapp_loops (lang, loopName, lineage, rank, param, value) VALUES ('en', 'submenu1', '2', 0, 'href2', 'wodgets')
	INSERT INTO cgiapp_loops (lang, loopName, lineage, rank, param, value) VALUES ('en', 'submenu1', '2', 0, 'atitle2', 'Finest wodgets')
	INSERT INTO cgiapp_loops (lang, loopName, lineage, rank, param, value) VALUES ('en', 'submenu1', '2', 1, 'href2', 'bladgers')
	INSERT INTO cgiapp_loops (lang, loopName, lineage, rank, param, value) VALUES ('en', 'submenu1', '2', 1, 'atitle2', 'Delectable bladgers')
	INSERT INTO cgiapp_loops (lang, loopName, lineage, rank, param, value) VALUES ('en', 'submenu1', '2', 2, 'href2', 'spodges')
	INSERT INTO cgiapp_loops (lang, loopName, lineage, rank, param, value) VALUES ('en', 'submenu1', '2', 2, 'atitle2', 'Exquisite spodges')
	
Now suppose that the bladger market is hot, and we need to further subdivide our menu. Then you might add the following rows:

	INSERT INTO cgiapp_loops (lang, loopName, lineage, rank, param, value) VALUES ('en', 'submenu2', '2,1', 0, 'href3', 'bladgers/runcible')
	INSERT INTO cgiapp_loops (lang, loopName, lineage, rank, param, value) VALUES ('en', 'submenu2', '2,1', 0, 'atitle3', 'Runcible bladgers')
	INSERT INTO cgiapp_loops (lang, loopName, lineage, rank, param, value) VALUES ('en', 'submenu2', '2,1', 1, 'href3', 'bladgers/collapsible')
	INSERT INTO cgiapp_loops (lang, loopName, lineage, rank, param, value) VALUES ('en', 'submenu2', '2,1', 1, 'atitle3', 'Collapsible bladgers')
	INSERT INTO cgiapp_loops (lang, loopName, lineage, rank, param, value) VALUES ('en', 'submenu2', '2,1', 2, 'href3', 'bladgers/goldplated')
	INSERT INTO cgiapp_loops (lang, loopName, lineage, rank, param, value) VALUES ('en', 'submenu2', '2,1', 2, 'atitle3', 'Gold plated bladgers')


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
	$self->{name} = shift;
	my %args = @_;
	$self->{config} = \%args;

	bless $self, $class;
	return $self;
}

=head2 structure


=cut

sub structure {
	my $self = shift;
	my $param = shift || "";

        # $dlineage are the "breadcrumbs" required to navigate our way through the database
	# and corresponds to the 'lineage' column on the cgiapp_structure table.
	my $dlineage = shift;
	$dlineage = "" unless defined $dlineage;

	# $tlineage are the "breadcrumbs" required to navigate our way through the HTML::Template structure.
	# It corresponds to the ARRAY ref used in $template->query(loop=> [....]) only that the
	# post "dot" string of the final array member (aka $loopname) is missing.
	my $tlineage = shift;
	$tlineage = [$self->{name}] unless defined $tlineage;

        my $prefix = $self->{cgiapp}->pagelookup_prefix(%{$self->{config}});
        my $page_id = $self->{page_id};
        my $dbh = $self->{cgiapp}->dbh;

	# This is what we actually want to return
	my @loop;

	$self->{work_to_be_done} = [] unless exists $self->{work_to_be_done};

	my $param_sql = join("", map {$_ =", p2.$_"} (split "," , $param));
        my $sql = "SELECT s.rank, p2.pageId $param_sql FROM ${prefix}structure s, ${prefix}pages p2, ${prefix}pages p1 WHERE p1.lang = p2.lang AND s.internalId = p2.internalId AND p1.pageId = '$page_id' AND s.lineage = '$dlineage' ORDER BY s.rank ASC";
	# First one pass over the loop
        my $sth = $dbh->prepare($sql) || croak $dbh->errstr;
        $sth->execute || croak $dbh->errstr;
        while(my $hash_ref = $sth->fetchrow_hashref) {

		my $current_rank = delete $hash_ref->{rank};

		# Now we need to add in any loop variables
		$self->__populate_lower_loops($dlineage, $tlineage, $hash_ref, $current_rank, $param);

		# We are finally ready to get this structure out of the door
		push @loop, $hash_ref;

	}
        croak $sth->errstr if $sth->err;
        $sth->finish;

	# Now go back over the remaining work
	while(@{$self->{work_to_be_done}}) {
		my $work = shift @{$self->{work_to_be_done}};
		&$work();
	}

        return \@loop;
}

=head2 __populate_lower_loops

A private function that does what is says.

=cut 

sub __populate_lower_loops {
	my $self = shift;
	my $dlineage = shift;
	my $tlineage = shift;
	my $current_row = shift;
	my $current_rank = shift;
	my $param = shift;
	my $comma = ',';
        my $new_dlineage = join $comma , (split /,/, $dlineage), $current_rank;
        my @new_tlineage = @$tlineage;
        my $thead = pop @new_tlineage;
	$thead .= ".structure";
	$thead .= "('$param')" if $param;
        push @new_tlineage, $thead;
        my @new_vars = $self->{template}->query(loop=>\@new_tlineage);
        foreach my $var (@new_vars) {

        	# exclude anything that is not a loop
                next if $self->{template}->query(name=>[@new_tlineage, $var]) eq 'VAR';

                # extract new loop name (following mechanics in HTML::Template::Plugin::Dot)
                my ($one, $the_rest) = split /\./, $var, 2;
                my $loopmap_name = 'this';
                $loopmap_name = $1 if $the_rest =~ s/\s*:\s*([_a-z]\w*)\s*$//;
		croak "can only handle structure: $the_rest" unless $the_rest =~ /^structure/;

                # Okay we have set up the structure but let's finish the current SQL
                # before populating this one
                my $new_loop = [];
                $current_row->{structure} = $new_loop;
                my $new_tlineage = [@new_tlineage, $one];
                push @{$self->{work_to_be_done}}, sub {
                	push @$new_loop,  @{$self->structure($param, $new_dlineage, $new_tlineage)};
                };
        }
	return;
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

    perldoc CGI::Application::Plugin::PageLookup::Menu


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

1; # End of CGI::Application::Plugin::PageLookup::Menu
