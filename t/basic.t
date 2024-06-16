#!perl
use Test2::V0;
use blib;

use DBD::rmysql qw(:all);

my $err = DBD::rmysql::Error->new();
my $c = rmysql_connect("dbi:rmysql:database=test;host=10.0.0.15", "test", "slapjack", $err);

is($err->code, NoError, "no error connecting");
ok($c, "connected");
diag $c;

my $statement = rmysql_prepare($c, "SELECT * FROM test", undef, $err);
is($err->code, NoError, "no error preparing");
diag $err->message;

rmysql_disconnect($c);


done_testing;

