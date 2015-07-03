#!/usr/bin/env perl

use POSIX qw(strftime);
use Data::Dumper;

use lib qw{ lib local/lib/perl5 };
# use CF::DB;
# use CF::Schema;
use Test::Most;
use Test::Mojo::More;
# use Test::DatabaseRow;

use lib qw{ t/lib };
my $t = Test::Mojo::More->new('Foo::Bar');

my $cfg_before = { %{$t->app->config} };
# diag Dumper( $cfg_before );
isa_ok( $t, 'Test::Mojo::More' );
isa_ok( $t->app, 'Foo::Bar' );
can_ok( $t->app, 'overload_cfg_for_site' );
isa_ok( $cfg_before, 'HASH', 'The config object' );

my $ini_additional = 't/conf.d/override_config.ini';
my $ini_bogus = 't/conf.d/bogus_config_file.ini';
throws_ok { $t->app->overload_cfg_for_site( $ini_additional ) } qr/config_files key expects an ARRAYREF/, '->inherit needs an array reference of config files';
throws_ok { $t->app->overload_cfg_for_site( [ $ini_additional, $ini_bogus ] ) } qr/Unable to read/, '->inherit needs config files it can read';

my $default_author_before = $cfg_before->{'default'}->{'author'};
my $client_url_before =  $cfg_before->{'client'}->{'url'};
is( $cfg_before->{'client'}->{'new_key'}, undef, 'The new_key does not exist in the original config' );

$t->app->overload_cfg_for_site( [ $ini_additional ] );
my $cfg_after = $t->app->config;
isa_ok( $cfg_after, 'HASH' );

isnt( $cfg_after->{'client'}->{'new_key'}, undef, 'The new_key does exist in the over-ridden config' );
is( $default_author_before, $cfg_after->{'default'}->{'author'}, 'Persistent default configuration has been preserved' );
isnt( $client_url_before, $cfg_after->{'client'}->{'url'}, 'Overrideable client configuration has been overridden' );

TODO: {

  my $why = 'TODO: Override Configuration. ';
  local $TODO = $why;

}

done_testing;

