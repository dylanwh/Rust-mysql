package DBD::rmysql::Error;

use FFI::Platypus 2.00;
use FFI::Platypus::Record;

sub init_record_layout {
    my($class, $ffi) = @_;

  record_layout_1($ffi, qw(
      enum code
      string(256) message
  ));
}

1;