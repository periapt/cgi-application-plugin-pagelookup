use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'CGI::Application::Plugin::PageLookup',
    AUTHOR              => q{Nicholas Bamber <nicholas@periapt.co.uk>},
    VERSION_FROM        => 'lib/CGI/Application/Plugin/PageLookup.pm',
    ABSTRACT_FROM       => 'lib/CGI/Application/Plugin/PageLookup.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
	'CGI::Application' => 0,
	'CGI::Application::Plugin::Forward' => 0,
	'CGI::Application::Plugin::DBH' => 0,
	'HTML::Template::Pluggable'=>0,
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'CGI-Application-Plugin-PageLookup-*' },
);
