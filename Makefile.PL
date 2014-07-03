use 5.014002;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Yandex::DirectAPI',
    VERSION_FROM      => 'lib/Yandex/DirectAPI.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT  => 'perl wrap for Yandex.Direct API', # retrieve abstract from module
       AUTHOR         => 'alexn <alexn@mm.st>') : ()),
);
