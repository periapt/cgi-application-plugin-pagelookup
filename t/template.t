#!perl -T

use strict;
use Test::More tests => 12;
use Test::Differences;
use lib qw(t/lib);
#use lib qw(../CGI-Application-PageLookup/lib);

BEGIN {
	use_ok( 'HTML::Template' );
	use_ok( 'CGI::Application::PageLookup' );
	use_ok( 'CGI::Application::Plugin::PageLookup' );
}

use DBI;
unlink "t/dbfile";


my $dbh = DBI->connect("dbi:SQLite:t/dbfile","","");
$dbh->do("create table cgiapp_pages (pageId, template, enrichment, home, path)");
$dbh->do("create table cgiapp_slogans (pageId, rank, A, B)");
$dbh->do("insert into  cgiapp_pages (pageId, template, enrichment, home, path) values('test1', 't/templ/test.tmpl', null, 'HOME', 'PATH')");
$dbh->do("insert into  cgiapp_pages (pageId, template, enrichment, home, path) values('test2', 't/templ/test.tmpl', null, 'HOME1', 'PATH1')");
$dbh->do("insert into  cgiapp_pages (pageId, template, enrichment, home, path) values('test3', 't/templ/testP.tmpl', 'TESTLOOP', 'HOME1', 'PATH1')");
$dbh->do("insert into  cgiapp_slogans (pageId, rank, A, B) values('test3', 1, 'I think', 'I am')");
$dbh->do("insert into  cgiapp_slogans (pageId, rank, A, B) values('test3', 2, 'I eat', 'I am happy')");

use CGI;
use TestApp;

$ENV{CGI_APP_RETURN_ONLY} = 1;

sub response_like {
        my ($app, $header_re, $body_re, $comment) = @_;

        local $ENV{CGI_APP_RETURN_ONLY} = 1;
        my $output = $app->run;
        my ($header, $body) = split /\r\n\r\n/m, $output;
        like($header, $header_re, "$comment (header match)");
        eq_or_diff($body,      $body_re,       "$comment (body match)");
}

{
        my $app = TestApp->new(QUERY => CGI->new(""));
        isa_ok($app, 'CGI::Application');

        response_like(
                $app,
                qr{^Content-Type: text/html},
                "Hello World: basic_test",
                'TestApp, blank query',
        );
}

{
my $html1=<<EOS
<html>
  <head><title>Test Template</title>
  <body>
  My Home Directory is HOME
  <p>
  My Path is set to PATH
  </body>
  </html>
EOS
;

        my $app = TestApp->new();
        $app->query(CGI->new({'rm' => 'test1'}));
        response_like(
                $app,
                qr{^Content-Type: text/html},
                $html1,
                'TestApp, test1'
        );
}

{
my $html1=<<EOS
<html>
  <head><title>Test Template</title>
  <body>
  My Home Directory is HOME1
  <p>
  My Path is set to PATH1
  </body>
  </html>
EOS
;

        my $app = TestApp->new();
        $app->query(CGI->new({'rm' => 'test2'}));
        response_like(
                $app,
                qr{^Content-Type: text/html},
                $html1,
                'TestApp, test2'
        );
}

{
my $html1=<<EOS
<html>
  <head><title>Test Template</title>
  <body>
  My Home Directory is HOME1
  <p>
  My Path is set to PATH1

	I think, therefore I am.

	I eat, therefore I am happy.

  </body>
  </html>
EOS
;

        my $app = TestApp->new();
        $app->query(CGI->new({'rm' => 'test3'}));
        response_like(
                $app,
                qr{^Content-Type: text/html},
                $html1,
                'TestApp, test3'
        );
}


