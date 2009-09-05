#!perl  

use strict;
use warnings;
use Test::More tests => 11;
use Test::Differences;
use lib qw(t/lib);

BEGIN {
	use_ok( 'HTML::Template' );
	use_ok( 'CGI::Application::Plugin::PageLookup' );
}

use DBI;
unlink "t/dbfile";


my $dbh = DBI->connect("dbi:SQLite:t/dbfile","","");
$dbh->do("create table cgiapp_pages (pageId, lang, internalId, home, path)");
$dbh->do("create table cgiapp_structure (internalId, template, changefreq)");
$dbh->do("create table cgiapp_lang (lang)");
$dbh->do("insert into  cgiapp_pages (pageId, lang, internalId, home, path) values('test1', 'en', 0, 'HOME', 'PATH')");
$dbh->do("insert into  cgiapp_pages (pageId, lang, internalId, home, path) values('test2', 'en', 1, 'HOME1', 'PATH1')");
$dbh->do("insert into  cgiapp_pages (pageId, lang, internalId, home, path) values('en/404', 'en', 2, 'HOME1', 'PATH1')");
$dbh->do("insert into  cgiapp_lang (lang) values('en')");
$dbh->do("insert into  cgiapp_structure(internalId, template, changefreq) values(0,'t/templ/test.tmpl', NULL)");
$dbh->do("insert into  cgiapp_structure(internalId, template, changefreq) values(1,'t/templ/test.tmpl', NULL)");
$dbh->do("insert into  cgiapp_structure(internalId, template, changefreq) values(2,'t/templ/testN.tmpl', NULL)");

use CGI;
use TestApp;

$ENV{CGI_APP_RETURN_ONLY} = 1;
my $params = {};

sub response_like {
        my ($app, $header_re, $body_re, $comment) = @_;

        local $ENV{CGI_APP_RETURN_ONLY} = 1;
        my $output = $app->run;
        my ($header, $body) = split /\r\n\r\n/m, $output;
        $header =~ s/\r\n/|/g;
        like($header, $header_re, "$comment (header match)");
        eq_or_diff($body,      $body_re,       "$comment (body match)");
}

{
        my $app = TestApp->new(QUERY => CGI->new(""));
        isa_ok($app, 'CGI::Application');

        response_like(
                $app,
                qr{^Encoding: utf-8\|Content-Type: text/html; charset=utf-8$},
                "Hello World: basic_test",
                'TestApp, blank query',
        );
}

{
my $html=<<EOS
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

	local $params->{pageid} = 'test1';
        my $app = TestApp->new(PARAMS=>$params);
        $app->query( CGI->new({'rm' => 'pagelookup_rm'}));
        response_like(
                $app,
                qr{^Encoding: utf-8\|Content-Type: text/html; charset=utf-8$},
                $html,
                'TestApp, test1'
        );
}

{
my $html=<<EOS
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

	local $params->{pageid} = 'test2';
        my $app = TestApp->new(PARAMS=>$params);
        $app->query(CGI->new({'rm' => 'pagelookup_rm', pageid=>'test2'}));
        response_like(
                $app,
                qr{^Encoding: utf-8\|Content-Type: text/html; charset=utf-8$},
                $html,
                'TestApp, test2'
        );
}

{
my $html=<<EOS
<html>
  <head><title>Test Template</title>
  <body>
  My Home Directory is HOME1
  <p>
  My Path is set to PATH1

  Did not find the page: test3
  </body>
  </html>
EOS
;

	local $params->{pageid} = 'test3';
        my $app = TestApp->new(PARAMS=>$params);
        $app->query(CGI->new({'rm' => 'pagelookup_rm'}));
        response_like(
                $app,
                qr{^Status: 404\|Encoding: utf-8\|Content-Type: text/html; charset=utf-8$},
                $html,
                'TestApp, notfound'
        );
}


