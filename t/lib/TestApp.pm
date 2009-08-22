package TestApp;

use strict;


use CGI::Application;
@TestApp::ISA = qw(CGI::Application);
use CGI::Application::Plugin::DBH (qw/dbh_config dbh/);
use CGI::Application::Plugin::PageLookup (qw/model model_load_tmpl/);
use CGI::Application::PageLookup;


sub setup {
        my $self = shift;

        $self->start_mode('basic_test');
        $self->run_modes(
		'basic_test'  => \&basic_test,
		'test1' => \&test1,
		'test2'=> \&test2,
		'test3'=>\&test3,
		'test4'=>\&test4
		);

}

sub basic_test {
        my $self = shift;
        return "Hello World: basic_test";
}

sub cgiapp_init {
        my $self = shift;
	# use the same args as DBI->connect();
	$self->dbh_config("dbi:SQLite:t/dbfile","","");

	$self->model(CGI::Application::PageLookup->new(dbh=>sub {return $self->dbh()},callbacks=>
        {
                TESTLOOP=> sub {
                        my ($hash_ref, $pageid, $dbh) = @_;
                        my $sql = "select A, B from cgiapp_slogans where pageid = '$pageid' order by rank asc";
                        my $sth = $dbh->prepare($sql) or die $dbh->errstr;
                        $sth->execute() or  die $dbh->errstr;
                        my @rows;
                        while(my $r = $sth->fetchrow_hashref) {
                                push @rows, $r;
                        }
                        die $dbh->errstr if $dbh->err;
                        $hash_ref->{TESTLOOP} = \@rows;
                }
        }
));
}

sub test1 {
        my $self = shift;
	return $self->model_load_tmpl('test1')->output;
}

sub test2 {
        my $self = shift;
	return $self->model_load_tmpl('test2')->output;
}

sub test3 {
        my $self = shift;
	return $self->model_load_tmpl('test3')->output;
}

sub test4 {
        my $self = shift;
	return $self->model_load_tmpl('test4')->output;
}


