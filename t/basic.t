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
my $c = rust_mysql_connect($dsn, $user, $pass, $err);

is($err->code, NoError, "no error connecting");
ok($c, "connected");
diag $c;

my $statement = rust_mysql_prepare($c, "SELECT now()", undef, $err);
is($err->code, NoError, "no error preparing");
diag $err->message;

rust_mysql_statement_destroy($statement);

rust_mysql_disconnect($c);


done_testing;

