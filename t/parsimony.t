#!perl  

use strict;
use warnings;
use Test::More tests => 10;
use Test::Differences;
use lib qw(t/lib);

BEGIN {
	use_ok( 'CGI::Application::Plugin::PageLookup' );
}

use DBI;
unlink "t/dbfile";

my $dbh = DBI->connect("dbi:SQLite:t/dbfile","","");
$dbh->do("create table cgiapp_pages (pageId, lang, internalId, home, path)");
$dbh->do("create table cgiapp_structure (internalId, template, lastmod, changefreq, priority)");
$dbh->do("create table cgiapp_lang (lang, collation)");
$dbh->do("insert into  cgiapp_pages (pageId, lang, internalId, home, path) values('en/test1', 'en', 0, 'HOME', 'PATH')");
$dbh->do("insert into  cgiapp_pages (pageId, lang, internalId, home, path) values('en/test2', 'en', 1, 'HOME1', 'PATH1')");
$dbh->do("insert into  cgiapp_pages (pageId, lang, internalId, home, path) values('en/test3', 'en', 2, 'HOME2', 'PATH2')");
$dbh->do("insert into  cgiapp_lang (lang, collation) values('en','GB')");
$dbh->do("insert into  cgiapp_structure(internalId, template, lastmod, changefreq, priority) values(0,'t/templ/testLO1.tmpl', '2009-8-11', 'daily', 0.8)");
$dbh->do("insert into  cgiapp_structure(internalId, template, lastmod, changefreq, priority) values(1,'t/templ/testLO2.tmpl', '2007-8-11', 'yearly', 0.7)");
$dbh->do("insert into  cgiapp_structure(internalId, template, lastmod, changefreq, priority) values(2,'t/templ/testLO.tmpl', '2007-8-11', 'yearly', 0.7)");

use CGI;
use TestApp;

$ENV{CGI_APP_RETURN_ONLY} = 1;
my $params = {remove=>['template','pageId','priority','internalId','lastmod','changefreq'],notfound_stuff=>1,xml_sitemap_base_url=>'http://xml/', 
	objects=>{
		test1=>sub {
			use SmartObjectTest;
			return SmartObjectTest->new(shift, shift, shift, shift);
		},
		test2=>'create_smart_object',
		test3=>'SmartObjectTest'
	}
};

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
        my $app = TestApp->new(QUERY => CGI->new(""), PARAMS=>$params);
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
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en-GB">
  <head><title>Test Template</title>
  <body>
  My Home Directory is HOME
  <p>
  My Path is set to PATH

  test1: en/test1|test1|VAR|hop
  </body>
  </html>
EOS
;

	local $params->{pageid} = 'en/test1';
        my $app = TestApp->new(PARAMS=>$params);
        $app->query( CGI->new({'rm' => 'pagelookup_rm'}));
        response_like(
                $app,
                qr{^Expires: \w\w\w, \d?\d \w\w\w \d\d\d\d \d\d:\d\d:\d\d \w\w\w\|Date: \w\w\w, \d?\d \w\w\w \d\d\d\d \d\d:\d\d:\d\d \w\w\w\|Encoding: utf-8\|Content-Type: text/html; charset=utf-8$},
                $html,
                'TestApp, test1'
        );
}

{
my $html=<<EOS
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en-GB">
  <head><title>Test Template</title>
  <body>
  My Home Directory is HOME1
  <p>
  My Path is set to PATH1

  test1: en/test2|test1|VAR|hop
  test2: en/test2|test2|VAR|skip
  </body>
  </html>
EOS
;

	local $params->{pageid} = 'en/test2';
        my $app = TestApp->new(PARAMS=>$params);
        $app->query(CGI->new({'rm' => 'pagelookup_rm'}));
        response_like(
                $app,
                qr{^Expires: \w\w\w, \d?\d \w\w\w \d\d\d\d \d\d:\d\d:\d\d \w\w\w\|Date: \w\w\w, \d?\d \w\w\w \d\d\d\d \d\d:\d\d:\d\d \w\w\w\|Encoding: utf-8\|Content-Type: text/html; charset=utf-8$},
                $html,
                'TestApp, test2'
        );
}


{
my $html=<<EOS
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en-GB">
  <head><title>Test Template</title>
  <body>
  My Home Directory is HOME2
  <p>
  My Path is set to PATH2

  test1: en/test3|test1|VAR|hop
  test2: en/test3|test2|VAR|skip
  test3: Just when you thought you had got the pattern: jump
  </body>
  </html>
EOS
;

	local $params->{pageid} = 'en/test3';
        my $app = TestApp->new(PARAMS=>$params);
        $app->query(CGI->new({'rm' => 'pagelookup_rm'}));
        response_like(
                $app,
                qr{^Expires: \w\w\w, \d?\d \w\w\w \d\d\d\d \d\d:\d\d:\d\d \w\w\w\|Date: \w\w\w, \d?\d \w\w\w \d\d\d\d \d\d:\d\d:\d\d \w\w\w\|Encoding: utf-8\|Content-Type: text/html; charset=utf-8$},
                $html,
                'TestApp, notfound'
        );
}

