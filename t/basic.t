#!perl
use Test2::V0;
use blib;

use Rust::mysql qw(:all);
my $dsn = $ENV{MYSQL_DSN};
my $user = $ENV{MYSQL_USER};
my $pass = $ENV{MYSQL_PASS};

# skip tests if we don't have a database to connect to
plan skip_all => "no database to connect to" unless $dsn;

my $err = Rust::mysql::Error->new();
my $c = rust_mysql_conn_new($dsn, $user, $pass, $err);

is($err->code, NoError, "no error connecting");
ok($c, "connected");
diag $c;

my $statement = rust_mysql_conn_prepare($c, "SELECT now(), ?", $err);
is($err->code, NoError, "no error preparing");
diag $err->message;

my $columns = rust_mysql_statement_columns($statement);
my $len  = rust_mysql_columns_len($columns);
is($len, 2, "two columns");
use Data::Dumper;
diag Dumper(rust_mysql_columns_names($columns));

rust_mysql_columns_drop($columns);

rust_mysql_statement_drop($statement);

rust_mysql_conn_drop($c);

done_testing;

