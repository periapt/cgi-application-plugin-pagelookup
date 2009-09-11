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
	'Carp' => 0,
	'CGI'=>0,
	'CGI::Application' => '4.31',
	'CGI::Application::Plugin::Forward' => 0,
	'CGI::Application::Plugin::DBH' => 0,
	'DBI' => 0,
	'Test::Differences' => 0,
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'CGI-Application-Plugin-PageLookup-*' },
);
