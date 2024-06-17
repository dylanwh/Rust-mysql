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
            if (rust_mysql_in_transaction($dbh->{rust_mysql_db_ptr})) {
                my $ok = rust_mysql_rollback($dbh->{rust_mysql_db_ptr}, $error);
                return $dbh->set_err($error->code, $error->message) if !$ok;
            }
        } else {
            if (!rust_mysql_in_transaction($dbh->{rust_mysql_db_ptr})) {
                my $ok = rust_mysql_begin_work($dbh->{rust_mysql_db_ptr}, $error);
                return $dbh->set_err($error->code, $error->message) if !$ok;
            }
        }

        return $val;
    }


    return $dbh->SUPER::STORE($attr, $val);
}

sub FETCH {
    my ($dbh, $attr) = @_;
    if ($attr eq 'AutoCommit') {
        return unless $dbh->{rust_mysql_db_ptr};
        return rust_mysql_in_transaction($dbh->{rust_mysql_db_ptr}) ? 0 : 1;
    }

    return $dbh->SUPER::FETCH($attr);
}

sub commit {
    my ($dbh) = @_;
    my $error = Rust::mysql::Error->new;
    my $ok = rust_mysql_commit($dbh->{rust_mysql_db_ptr}, $error);
    return $dbh->set_err($error->code, $error->message) if !$ok;
    return 1;
}

sub rollback {
    my ($dbh) = @_;
    my $error = Rust::mysql::Error->new;
    my $ok = rust_mysql_rollback($dbh->{rust_mysql_db_ptr}, $error);
    return $dbh->set_err($error->code, $error->message) if !$ok;
    return 1;
}

sub prepare {
    my ($dbh, $statement, $attr) = @_;

    my ($outer, $sth) = DBI::_new_sth($dbh, {});

    my $error = Rust::mysql::Error->new;
    my $ptr = rust_mysql_prepare($dbh->{rust_mysql_db_ptr}, $statement, $error);
    return $dbh->set_err($error->code, $error->message) if !$ptr;
    $sth->{rust_mysql_st_ptr} = $ptr;

    return $outer;
}


sub DESTROY {
    my ($dbh) = @_;
    if ($dbh->{rust_mysql_db_ptr}) {
        rust_mysql_disconnect($dbh->{rust_mysql_db_ptr});
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
    return $drh->set_err($err->code, $err->message) if !$conn;

    $dbh->{rust_mysql_db_ptr} = $conn;

    return $outer;
}

package DBD::rust_mysql::st;
our $imp_data_size = 0;

sub execute {
    my ($sth, @bind_values) = @_;

    my $error = Rust::mysql::Error->new;
    my $ok = rust_mysql_execute($sth->{rust_mysql_st_ptr}, \@bind_values, $error);
    return $sth->set_err($error->code, $error->message) if !$ok;

    return 1;

}

sub DESTROY {
    my ($sth) = @_;
    if ($sth->{rust_mysql_st_ptr}) {
        rust_mysql_statement_destroy($sth->{rust_mysql_stmt});
    }

    return $sth->SUPER::DESTROY;
}

1;