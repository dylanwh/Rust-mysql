package Rust::mysql::Attribs;

use FFI::Platypus 2.00;
use FFI::Platypus::Record;

sub init_record_layout {
    my($class, $ffi) = @_;

  record_layout_1($ffi, qw(
      bool debug
  ));
}

1;