#!perl  

use strict;
use warnings;
use Test::More tests => 16;
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
$dbh->do("insert into  cgiapp_pages (pageId, lang, internalId, home, path) values('de/test1', 'de', 0, 'HEIMAT', 'Stra&szlig;e')");
$dbh->do("insert into  cgiapp_pages (pageId, lang, internalId, home, path) values('de/test2', 'de', 1, 'HEIMAT1', 'Stra&szlig;e1')");
$dbh->do("insert into  cgiapp_pages (pageId, lang, internalId, home, path) values('en/notfound', 'en', 2, 'HOME', 'PATH')");
$dbh->do("insert into  cgiapp_pages (pageId, lang, internalId, home, path) values('de/notfound', 'de', 2, 'HEIMAT', 'Stra&szlig;e3')");
$dbh->do("insert into  cgiapp_lang (lang, collation) values('en','GB')");
$dbh->do("insert into  cgiapp_lang (lang, collation) values('de','DE')");
$dbh->do("insert into  cgiapp_structure(internalId, template, lastmod, changefreq, priority) values(0,'t/templ/testLO.tmpl', '2009-8-11', 'daily', 0.8)");
$dbh->do("insert into  cgiapp_structure(internalId, template, lastmod, changefreq, priority) values(1,'t/templ/testLO.tmpl', '2007-8-11', 'yearly', 0.7)");
$dbh->do("insert into  cgiapp_structure(internalId, template, lastmod, changefreq, priority) values(2,'t/templ/testNLO.tmpl', '2009-8-11', 'never', NULL)");

use CGI;

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

SKIP: {
	eval { require HTML::Template::Pluggable;};
	skip "HTML::Template::Pluggable required", 15 if $@; 
	eval { require UNIVERSAL::require;};
	skip "UNIVERSAL::require required", 15 if $@; 
	eval { require TestApp;};
	skip "TestApp required", 15 if $@; 
	
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
  test2: en/test1|test2|VAR|skip
  test3: Just when you thought you had got the pattern: jump
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
  test3: Just when you thought you had got the pattern: jump
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
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="de-DE">
  <head><title>Test Template</title>
  <body>
  My Home Directory is HEIMAT
  <p>
  My Path is set to Stra&szlig;e

  test1: de/test1|test1|VAR|hop
  test2: de/test1|test2|VAR|skip
  test3: Gerade als Sie dachten, Sie hatten das Muster gehabt:  Sprung
  </body>
  </html>
EOS
;

	local $params->{pageid} = 'de/test1';
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
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="de-DE">
  <head><title>Test Template</title>
  <body>
  My Home Directory is HEIMAT1
  <p>
  My Path is set to Stra&szlig;e1

  test1: de/test2|test1|VAR|hop
  test2: de/test2|test2|VAR|skip
  test3: Gerade als Sie dachten, Sie hatten das Muster gehabt:  Sprung
  </body>
  </html>
EOS
;

	local $params->{pageid} = 'de/test2';
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
  My Home Directory is HOME
  <p>
  My Path is set to PATH

  My error message for you: en/test3

  test1: en/notfound|test1|VAR|hop
  test2: en/notfound|test2|VAR|skip
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
                qr{^Status: 404\|Expires: \w\w\w, \d?\d \w\w\w \d\d\d\d \d\d:\d\d:\d\d \w\w\w\|Date: \w\w\w, \d?\d \w\w\w \d\d\d\d \d\d:\d\d:\d\d \w\w\w\|Encoding: utf-8\|Content-Type: text/html; charset=utf-8$},
                $html,
                'TestApp, notfound'
        );
}

{
my $html=<<EOS
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="de-DE">
  <head><title>Test Template</title>
  <body>
  My Home Directory is HEIMAT
  <p>
  My Path is set to Stra&szlig;e3

  My error message for you: de/test3

  test1: de/notfound|test1|VAR|hop
  test2: de/notfound|test2|VAR|skip
  test3: Gerade als Sie dachten, Sie hatten das Muster gehabt:  Sprung

  </body>
  </html>
EOS
;

	local $params->{pageid} = 'de/test3';
        my $app = TestApp->new(PARAMS=>$params);
        $app->query(CGI->new({'rm' => 'pagelookup_rm'}));
        response_like(
                $app,
                qr{^Status: 404\|Expires: \w\w\w, \d?\d \w\w\w \d\d\d\d \d\d:\d\d:\d\d \w\w\w\|Date: \w\w\w, \d?\d \w\w\w \d\d\d\d \d\d:\d\d:\d\d \w\w\w\|Encoding: utf-8\|Content-Type: text/html; charset=utf-8$},
                $html,
                'TestApp, notfound'
        );
}
}

