#!perl
use Test2::V0;
use blib;

use DBD::rmysql qw(:all);
my $dsn = $ENV{MYSQL_DSN};
my $user = $ENV{MYSQL_USER};
my $pass = $ENV{MYSQL_PASS};

# skip tests if we don't have a database to connect to
plan skip_all => "no database to connect to" unless $dsn;

my $err = DBD::rmysql::Error->new();
my $c = rmysql_connect($dsn, $user, $pass, $err);

is($err->code, NoError, "no error connecting");
ok($c, "connected");
diag $c;

my $statement = rmysql_prepare($c, "SELECT now()", undef, $err);
is($err->code, NoError, "no error preparing");
diag $err->message;

rmysql_statement_destroy($statement);

rmysql_disconnect($c);


done_testing;

