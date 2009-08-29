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
$dbh->do("create table cgiapp_pages (pageId, lang, template, home, path)");
$dbh->do("create table cgiapp_lang (lang)");
$dbh->do("insert into  cgiapp_pages (pageId, lang, template, home, path) values('test1', 'en', 't/templ/test.tmpl', 'HOME', 'PATH')");
$dbh->do("insert into  cgiapp_pages (pageId, lang, template, home, path) values('test2', 'en', 't/templ/test.tmpl', 'HOME1', 'PATH1')");
$dbh->do("insert into  cgiapp_pages (pageId, lang, template, home, path) values('en/404', 'en', 't/templ/testN.tmpl', 'HOME1', 'PATH1')");
$dbh->do("insert into  cgiapp_lang (lang) values('en')");

use CGI;
use TestApp;

$ENV{CGI_APP_RETURN_ONLY} = 1;

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

        my $app = TestApp->new();
        $app->query( CGI->new({'rm' => 'pagelookup_rm', pageid=>'test1'}));
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

        my $app = TestApp->new();
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

        my $app = TestApp->new();
        $app->query(CGI->new({'rm' => 'pagelookup_rm', pageid=>'test3'}));
        response_like(
                $app,
                qr{^Status: 404\|Encoding: utf-8\|Content-Type: text/html; charset=utf-8$},
                $html,
                'TestApp, notfound'
        );
}


