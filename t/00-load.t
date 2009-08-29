#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'CGI::Application::Plugin::PageLookup' );
}

diag( "Testing CGI::Application::Plugin::PageLookup $CGI::Application::Plugin::PageLookup::VERSION, Perl $], $^X" );
