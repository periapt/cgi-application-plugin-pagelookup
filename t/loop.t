#!perl -T

use Test::More tests => 14;
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
$dbh->do("create table cgiapp_pages (pageId, template, extra, enrichment, home, path)");
$dbh->do("create table cgiapp_values (valueId, value, loopId)");
$dbh->do("create table cgiapp_linkage (pageId, param, valueId)");
$dbh->do("create table cgiapp_loops (loopId, rank, pageId)");
$dbh->do("insert into  cgiapp_pages (pageId, template, extra, enrichment, home, path) values('test1', 't/templ/testE.tmpl', 0, null, 'HOME', 'PATH')");
$dbh->do("insert into  cgiapp_pages (pageId, template, extra, enrichment, home, path) values('test2', 't/templ/testE.tmpl', 1, null, 'HOME1', 'PATH1')");
$dbh->do("insert into  cgiapp_pages (pageId, template, extra, enrichment, home, path) values('test3', 't/templ/testEP.tmpl', 1, null, 'HOME1', 'PATH1')");
$dbh->do("insert into  cgiapp_pages (pageId, template, extra, enrichment, home, path) values('test4', 't/templ/testEP.tmpl', 1, null, 'HOME4', 'PATH4')");
$dbh->do("insert into  cgiapp_linkage (pageId, param, valueId) values('test2', 'extra_test', 1)");
$dbh->do("insert into  cgiapp_linkage (pageId, param, valueId) values('test3', 'extra_test', 1)");
$dbh->do("insert into  cgiapp_linkage (pageId, param, valueId) values('test4', 'extra_test', 2)");
$dbh->do("insert into  cgiapp_linkage (pageId, param, valueId) values('test3', 'TESTLOOP', 3)");
$dbh->do("insert into  cgiapp_linkage (pageId, param, valueId) values('test4', 'TESTLOOP', 3)");
$dbh->do("insert into  cgiapp_values (valueId, value) values(1, 'This should not appear in /test1')");
$dbh->do("insert into  cgiapp_values (valueId, value) values(2, 'This should appear in /test4')");
$dbh->do("insert into  cgiapp_values (valueId, loopId) values(3, 1)");
$dbh->do("insert into  cgiapp_loops(loopId,rank,pageId) values(1, 1, 'loop1')");
$dbh->do("insert into  cgiapp_loops(loopId,rank,pageId) values(1, 2, 'loop2')");
$dbh->do("insert into  cgiapp_linkage (pageId, param, valueId) values('loop1', 'A', 4)");
$dbh->do("insert into  cgiapp_linkage (pageId, param, valueId) values('loop1', 'B', 5)");
$dbh->do("insert into  cgiapp_linkage (pageId, param, valueId) values('loop2', 'A', 6)");
$dbh->do("insert into  cgiapp_linkage (pageId, param, valueId) values('loop2', 'B', 7)");
$dbh->do("insert into  cgiapp_values (valueId, value) values(4, 'I think')");
$dbh->do("insert into  cgiapp_values (valueId, value) values(5, 'I am')");
$dbh->do("insert into  cgiapp_values (valueId, value) values(6, 'I eat')");
$dbh->do("insert into  cgiapp_values (valueId, value) values(7, 'I am happy')");

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

This should not appear in /test1

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


This should not appear in /test1

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


{
my $html1=<<EOS
<html>
  <head><title>Test Template</title>
  <body>
  My Home Directory is HOME4
  <p>
  My Path is set to PATH4

	I think, therefore I am.

	I eat, therefore I am happy.


This should appear in /test4

  </body>
  </html>
EOS
;

        my $app = TestApp->new();
        $app->query(CGI->new({'rm' => 'test4'}));
        response_like(
                $app,
                qr{^Content-Type: text/html},
                $html1,
                'TestApp, test4'
        );
}

