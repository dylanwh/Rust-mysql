use ExtUtils::MakeMaker;
use FFI::Build::MM;

my $fbmm = FFI::Build::MM->new;




WriteMakefile($fbmm->mm_args(
    ABSTRACT       => 'FFI extension for rust_mysql',
    DISTNAME       => 'Rust-mysql',
    NAME           => 'Rust::mysql',
    VERSION_FROM   => 'lib/Rust/mysql.pm',
    BUILD_REQUIRES => {
        'FFI::Build::MM'          => '1.00',
        'FFI::Build::File::Cargo' => '0.07',
    },
    PREREQ_PM => {
        'FFI::Platypus'             => '1.00',
        'FFI::Platypus::Lang::Rust' => '0.07',
    },
));

sub MY::postamble {
    $fbmm->mm_postamble;
}