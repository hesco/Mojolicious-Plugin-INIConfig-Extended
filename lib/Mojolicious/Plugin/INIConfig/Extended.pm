package Mojolicious::Plugin::INIConfig::Extended;
use Mojo::Base 'Mojolicious::Plugin::INIConfig';
use Config::Tiny;
use File::Spec::Functions 'file_name_is_absolute';
use Mojo::Util qw/encode decode slurp/;
use Data::Dumper;

our $VERSION = '0.01';

sub register {
  my ($self, $app, $conf) = @_;
  
  # Config file
  my $file = $conf->{file} || $ENV{MOJO_CONFIG};
  $file ||= $app->moniker . '.' . ($conf->{ext} || 'ini');

  # Mode specific config file
  my $mode = $file =~ /^(.*)\.([^.]+)$/ ? join('.', $1, $app->mode, $2) : '';

  my $home = $app->home;
  $file = $home->rel_file($file) unless file_name_is_absolute $file;
  $mode = $home->rel_file($mode) if $mode && !file_name_is_absolute $mode;
  $mode = undef unless $mode && -e $mode;

  # Read config file
  my $config = {};

  if (-e $file) {
    $config = $self->load($file, $conf, $app);
  # check to see if we should overload a base configuration
  } elsif( exists $conf->{'base_config'} && exists $conf->{'config_files'} ) {
    $config = $self->inherit( $conf );
  # Check for default and mode specific config file
  } elsif (!$conf->{default} && !$mode) {
    die qq{Config file "$file" missing, maybe you need to create it?\n};
  }

  # Merge everything
  if ($mode) {
    my $mode_config = $self->load($mode, $conf, $app);
    for my $key (keys %$mode_config) {
      $config->{$key}
        = {%{$config->{$key} || {}}, %{$mode_config->{$key} || {}}};
    }
  }
  if ($conf->{default}) {
    my $default_config = $conf->{default};
    for my $key (keys %$default_config) {
      $config->{$key}
        = {%{$default_config->{$key} || {}}, %{$config->{$key} || {}}, };
    }
  }
  my $current = $app->defaults(config => $app->config)->config;
  for my $key (keys %$config) {
    %{$current->{$key}}
      = (%{$current->{$key} || {}}, %{$config->{$key} || {}});
  }

  return $current;
}

sub inherit {
  my $self = shift;
  my $args = shift;
  # print STDERR '::inherit() got these $args: ' . Dumper( $args );

  die 'config_files key expects an ARRAYREF' 
    unless ref $args->{'config_files'} eq 'ARRAY';
  foreach my $ini ( @{$args->{'config_files'}} ){
    die 'Unable to read ' . Dumper( $ini ) unless -r $ini;
  }
  my $cfg_overloaded;
  if(ref $args->{'base_config'} ne 'HASH'){
    return;
  } else {
    my $cfg_overloaded = $args->{'base_config'};
    my $cfg_overload = Config::Tiny->read( $args->{'config_files'}->[0], 'utf8' );
    # print STDERR '->inherit() says the $cfg_overload is: ' . Dumper $cfg_overload;
    my $stanzas_base_config = _get_stanzas( $args->{'base_config'} );
    my $stanzas_cfg_overload = _get_stanzas( $cfg_overload );
    # print STDERR '->inherit() says stanza include: ' . Dumper $stanzas;
    foreach my $stanza ( @{$stanzas_base_config}, @{$stanzas_cfg_overload} ){
      my $keys_base_config = _get_keys( $args->{'base_config'}, $stanza );
      my $keys_cfg_overload = _get_keys( $cfg_overload, $stanza );
      # print STDERR "->inherit() says base configuration's $stanza stanza includes: \n";
      foreach my $key ( @{$keys_base_config}, @{$keys_cfg_overload} ){
        # print STDERR "\t" . $key . ' => ' . $cfg_overloaded->{$stanza}->{$key} . "\n";
        $cfg_overloaded->{$stanza}->{$key} 
          = exists $cfg_overload->{$stanza}->{$key}
          ? $cfg_overload->{$stanza}->{$key}
          : $cfg_overloaded->{$stanza}->{$key}
      }
    }
  }

  return $cfg_overloaded;
}

sub _get_stanzas {
  my $cfg = shift;
  my @stanzas = keys %{$cfg};
  return \@stanzas;
}

sub _get_keys {
  my $cfg = shift;
  my $stanza = shift;
  my @keys = exists $cfg->{$stanza}
    ? keys %{$cfg->{$stanza}}
    : ();
  return \@keys;
}

1;

=head1 NAME

Mojolicious::Plugin::INIConfig::Extended - Mojolicious Plugin to overload a Configuration 

=head1 CAUTION

B<This module is alpha release. the feature will be changed without warnings.>

=head1 SYNOPSIS

  # myapp.ini
  [section]
  foo=bar
  music_dir=<%= app->home->rel_dir('music') %>

  # Mojolicious
  my $config = $self->plugin('INIConfig::Extended');

  # Mojolicious::Lite
  my $config = plugin 'INIConfig';

  # foo.html.ep
  %= $config->{section}{foo}

  # The configuration is available application wide
  my $config = app->config;

  # Everything can be customized with options
  my $config = plugin INIConfig => {file => '/etc/myapp.conf'};

=head1 DESCRIPTION

L<Mojolicious::Plugin::INIConfig> is a INI configuration plugin that
preprocesses its input with L<Mojo::Template>.

The application object can be accessed via C<$app> or the C<app> function. You
can extend the normal config file C<myapp.ini> with C<mode> specific ones
like C<myapp.$mode.ini>. A default configuration filename will be generated
from the value of L<Mojolicious/"moniker">.

The code of this plugin is a good example for learning to build new plugins,
you're welcome to fork it.

=head1 OPTIONS

L<Mojolicious::Plugin::INIConfig::Extended> inherits all options from
L<Mojolicious::Plugin::INIConfig> and supports the following new ones.

=head2 base_config 

  # Mojolicious::Lite
  plugin Config => { base_config => $app->cfg, file => 'conf.d/example.com/site_config.ini' }; 

Overload a base configuration with key->value pairs from an 
additional configuration file.  

=head2 config_files 

  # Mojolicious::Lite
  plugin Config => { config_files => [ qw{ conf.d/base_config.ini conf.d/example.com/site_config.ini ] };

Build configuration from an ordered list of configuration files, 
subsequent ones overloading preceeding ones.  

=head1 METHODS

L<Mojolicious::Plugin::INIConfig::Extended> inherits all methods from
L<Mojolicious::Plugin::INIConfig> and implements the following new ones.

=head2 inherit

  $plugin->inherit($content, $file, $conf, $app);

Overload a Config::Tiny configuration, return it as $app->cfg

=head1 BACKWARDS COMPATIBILITY POLICY

At least for now, in its early stages of development, 
this module should be considered experimental.  
EXPERIMENTAL features may be changed without warnings.

=head1 BUGS

Please tell me bugs if you find bug.

C<< <hesco at yourmessagedelivered.com> >>

L<http://github.com/yuki-kimoto/Mojolicious-Plugin-INIConfig>

=head1 COPYRIGHT & LICENSE

Copyright 2013-2013 Yuki Kimoto, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
