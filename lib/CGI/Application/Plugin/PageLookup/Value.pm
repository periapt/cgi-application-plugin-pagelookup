package CGI::Application::Plugin::PageLookup::Value;

use warnings;
use strict;

=head1 NAME

CGI::Application::Plugin::PageLookup::Value - Manage values scattered across a website

=head1 VERSION

Version 1.0

=cut

our $VERSION = '1.0';
our $AUTOLOAD;

=head1 DESCRIPTION

This module interprets suitably registered dot notation template variables
by looking up the part of the variable after the dot in a table. If possible
it will match on on the exact page id, failing that it will match on website-wide
pages that match on language.

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use CGI::Application::Plugin::PageLookup::Value;

    my $foo = CGI::Application::Plugin::PageLookup::Value->new();
    ...

=head1 DATABASE

=head1 FUNCTIONS

=head2 new

=cut

sub new {
	my $class = shift;
	my $self = {};
	$self->{cgiapp} = shift;
	$self->{page_id} = shift;
	$self->{template} = shift;
	$self->{hash_ref} = shift;
	my %args = $self->{cgiapp}->pagelookup_get_config(@_);
	$self->{config} = \%args;
	bless $self, $class;
	return $self;
}

=head2 can

=cut

sub can {
	return 1;
}

=head2 AUTOLOAD 

=cut

sub AUTOLOAD {
	my $self = shift;
	my @method = split /::/, $AUTOLOAD;
	my $param = pop @method;
	my $prefix = $self->{cgiapp}->pagelookup_prefix;
	my $page_id = $self->{page_id};
	my $dbh = $self->{cgiapp}->dbh;
	my @sql = (
		"SELECT v.value FROM ${prefix}values v WHERE v.pageId = '$page_id' AND v.param = '$param'",
		"SELECT v.value FROM ${prefix}values v, ${prefix}pages p WHERE v.pageId IS NULL AND v.param = '$param' AND v.lang = p.lang AND p.pageId = '$page_id'");
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
}

=head2 DESTRROY

=cut

sub DESTROY {
}

=head1 AUTHOR

Nicholas Bamber, C<< <nicholas at periapt.co.uk> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-cgi-application-plugin-pagelookup-value at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CGI-Application-Plugin-PageLookup-Value>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc CGI::Application::Plugin::PageLookup::Value


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=CGI-Application-Plugin-PageLookup-Value>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/CGI-Application-Plugin-PageLookup-Value>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/CGI-Application-Plugin-PageLookup-Value>

=item * Search CPAN

L<http://search.cpan.org/dist/CGI-Application-Plugin-PageLookup-Value/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 Nicholas Bamber.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of CGI::Application::Plugin::PageLookup::Value
