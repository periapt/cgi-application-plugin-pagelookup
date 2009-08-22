use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'CGI::Application::Plugin::PageLookup',
    AUTHOR              => 'Nicholas Bamber <nicholas@periapt.co.uk>',
    VERSION_FROM        => 'lib/CGI/Application/Plugin/PageLookup.pm',
    ABSTRACT_FROM       => 'lib/CGI/Application/Plugin/PageLookup.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
	'CGI::Application::PageLookup'=>0
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'CGI-Application-Plugin-PageLookup-*' },
);
