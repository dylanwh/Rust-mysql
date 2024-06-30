#!perl

use Test2::V0;
use blib;
use DBI;

my $dsn = $ENV{MYSQL_DSN};
my $user = $ENV{MYSQL_USER};
my $pass = $ENV{MYSQL_PASS};

# skip tests if we don't have a database to connect to
plan skip_all => "no database to connect to" unless $dsn || $user || $pass;

die "invalid dsn" unless $dsn =~ /^dbi:rust_mysql:/;

my $dbh = DBI->connect($dsn, $user, $pass, { RaiseError => 1, AutoCommit => 1 });

my $sth = $dbh->prepare("SELECT now()");

$sth->execute();

pass;

done_testing;