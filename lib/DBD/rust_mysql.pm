package DBD::rust_mysql;

use strict;
use warnings;
use Rust::mysql;

my $drh = undef;

sub driver {
    return $drh if $drh;
    my ($class, $attr) = @_;

    $class .= '::dr';

    $drh = DBI::_new_drh($class, {
        'Name' => 'rust_mysql',
        'Version' => $Rust::mysql::VERSION,
        'Attribution' => 'DBD::rust_mysql by Dylan Hardison',
    });

    return $drh;
}

sub CLONE {
    undef $drh;
}

package DBD::rust_mysql::db;
our $imp_data_size = 0;

use Rust::mysql qw(:all);

sub STORE {
    my ($dbh, $attr, $val) = @_;
    if ($attr eq 'AutoCommit') {
        my $error = Rust::mysql::Error->new;
        if ($val) {
            if (rust_mysql_in_transaction($dbh->{rust_mysql_conn})) {
                rust_mysql_rollback($dbh->{rust_mysql_conn}, $error);
                return $dbh->set_err($error->code, $error->message) if $error->code;
            }
        } else {
            if (!rust_mysql_in_transaction($dbh->{rust_mysql_conn})) {
                rust_mysql_begin_work($dbh->{rust_mysql_conn}, $error);
                return $dbh->set_err($error->code, $error->message) if $error->code;
            }
        }

        return $val;
    }


    return $dbh->SUPER::STORE($attr, $val);
}

sub FETCH {
    my ($dbh, $attr) = @_;
    if ($attr eq 'AutoCommit') {
        return unless $dbh->{rust_mysql_conn};
        return rust_mysql_in_transaction($dbh->{rust_mysql_conn}) ? 0 : 1;
    }

    return $dbh->SUPER::FETCH($attr);
}

sub commit {
    my ($dbh) = @_;
    my $error = Rust::mysql::Error->new;
    rust_mysql_commit($dbh->{rust_mysql_conn}, $error);
    return $dbh->set_err($error->code, $error->message) if $error->code;
    return 1;
}

sub rollback {
    my ($dbh) = @_;
    my $error = Rust::mysql::Error->new;
    rust_mysql_rollback($dbh->{rust_mysql_conn}, $error);
    return $dbh->set_err($error->code, $error->message) if $error->code;
    return 1;
}

sub DESTROY {
    my ($dbh) = @_;
    if ($dbh->{rust_mysql_conn}) {
        rust_mysql_disconnect($dbh->{rust_mysql_conn});
    }

    return $dbh->SUPER::DESTROY;
}

package DBD::rust_mysql::dr;
our $imp_data_size = 0;

use Rust::mysql qw(:all);

sub connect {
    my ($drh, $dsn, $user, $auth, $attr) = @_;

    my ($outer, $dbh) = DBI::_new_dbh($drh, {
        Name => $dsn,
    });

    my $err = Rust::mysql::Error->new;
    my $conn = rust_mysql_connect($dsn // "", $user // "", $auth // "", $err);
    if (!$conn) {
        return $drh->set_err($err->code, $err->message);
    }

    use Data::Dumper;
    $dbh->{rust_mysql_conn} = $conn;

    return $outer;
}



1;