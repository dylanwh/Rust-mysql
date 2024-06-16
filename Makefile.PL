use ExtUtils::MakeMaker;
use FFI::Build::MM;

my $fbmm = FFI::Build::MM->new;




WriteMakefile($fbmm->mm_args(
    ABSTRACT       => 'FFI extension for rmysql',
    DISTNAME       => 'DBD-rmysql',
    NAME           => 'DBD::rmysql',
    VERSION_FROM   => 'lib/DBD/rmysql.pm',
    BUILD_REQUIRES => {
        'FFI::Build::MM'          => '1.00',
        'FFI::Build::File::Cargo' => '0.07',
    },
    PREREQ_PM => {
        'FFI::Platypus'             => '1.00',
        'FFI::Platypus::Lang::Rust' => '0.07',
        'FFI::Platypus::Type::Enum' => '0.06',
    },
));

sub MY::postamble {
    $fbmm->mm_postamble;
}