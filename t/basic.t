#!perl  

use strict;
use warnings;
use Test::More;
use Test::Database;
use Test::Differences;
use lib qw(t/lib);

# get all available handles
my @handles = Test::Database->handles({dbd=>'SQLite'});

# plan the tests
plan tests => 2 + 9 * @handles;

BEGIN {
	use_ok( 'HTML::Template' );
	use_ok( 'CGI::Application::Plugin::PageLookup' );
}

use DBI;
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

# run the tests
for my $handle (@handles) {
       diag "Testing with " . $handle->dbd();    # mysql, SQLite, etc.

       # let $handle do the connect()
       my $dbh = $handle->dbh();
       if ($ENV{TEST_DATABASE_DROP}) {
          goto DROP;
       }
       $params->{'::Plugin::DBH::dbh_config'}=[$dbh];

       $dbh->do("create table cgiapp_pages (pageId varchar(255), lang varchar(2), internalId int, home TEXT, path TEXT)");
       $dbh->do("create table cgiapp_structure (internalId int, template varchar(20), changefreq varchar(20))");
       $dbh->do("create table cgiapp_lang (lang varchar(2))");
       $dbh->do("insert into  cgiapp_pages (pageId, lang, internalId, home, path) values('test1', 'en', 0, 'HOME', 'PATH')");
       $dbh->do("insert into  cgiapp_pages (pageId, lang, internalId, home, path) values('test2', 'en', 1, 'HOME1', 'PATH1')");
       $dbh->do("insert into  cgiapp_pages (pageId, lang, internalId, home, path) values('en/404', 'en', 2, 'HOME1', 'PATH1')");
       $dbh->do("insert into  cgiapp_lang (lang) values('en')");
       $dbh->do("insert into  cgiapp_structure(internalId, template, changefreq) values(0,'t/templ/test.tmpl', NULL)");
       $dbh->do("insert into  cgiapp_structure(internalId, template, changefreq) values(1,'t/templ/test.tmpl', NULL)");
       $dbh->do("insert into  cgiapp_structure(internalId, template, changefreq) values(2,'t/templ/testN.tmpl', NULL)");
#	my $sql = "SELECT s.template, s.changefreq, p.*, l.* FROM cgiapp_pages p JOIN cgiapp_lang l, cgiapp_structure s ON p.lang = l.lang AND p.pageId = \'test1\' AND p.internalId = s.internalId";
#	my $sql = "SELECT * FROM cgiapp_pages p JOIN cgiapp_lang l ON p.lang = l.lang, cgiapp_pages p JOIN cgiapp_structure s ON p.internalId = s.internalId WHERE p.pageId = \'test1\'";
#       my $sth = $dbh->prepare($sql) || croak $dbh->errstr;
#	$sth->execute || croak $sth->errstr;
#	print $sth->fetchrow_hashref;
#	$sth->finish;
#	goto DROP;

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


DROP:  $dbh->do("drop table cgiapp_pages");
       $dbh->do("drop table cgiapp_structure");
       $dbh->do("drop table cgiapp_lang");
}
