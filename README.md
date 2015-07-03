# Mojolicious-Plugin-INIConfig-Extended
Provide configuration inheritance and overloading

This module seeks to do for Mojolicious::Plugin::INIConfig, 
what my earlier cpan contribution, Config::Simple::Extended 
did for Config::Simple.  

The code here barely refactors the INIConfig plugin's ->register method 
to route to a new ->inherit method when appropriate.  I copied over the 
test suite from ::INIConfig and ::INIConfig::Extended introduces no 
regression and may be used as a drop in replacement.  

# SYNOPSIS

   $self->plugin('INIConfig::Extended', {
     base_config => $self->app->config,
    config_files => \@config_files });

# KNOWN BUGS 

For the moment, as currently implemented, the ->inherit method, although 
it expects both a base_config (hash ref) and a config_files (array ref), 
and its design anticipates in the future processing that array of config files 
to overload the configuration; it currently only processes the first ini file 
in that array.  All other config files will be ignored.  

Patches with tests are welcome in the form of a Pull Request.  Or with 
patience I will soon enough encounter a use case which should make me 
return to this project and to complete the implementation of its original 
design.  For the moment, though, this serves my immediate needs.  For clues 
on how to invoke the ->inherit method to overcome this limitation please 
see `perldoc Config::Simple::Extended`.  

# LICENSE

This module is released under the terms of the Gnu Public License.  

# AUTHOR 

Hugh Esco <hesco@yourmessagedelivered.com>

# COPYRIGHT

Copyright 2015 
Hugh Esco and YMD Partners LLC

