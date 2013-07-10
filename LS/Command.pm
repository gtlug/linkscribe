package LS::Command;
use Mouse;
with qw(LS::Base LS::Cache);

##This should only be here until Module::Pluggable is setup
use LS::Command::Example;

sub refreshPlugins {
	my $self = shift;
	## Find all plugins in LS::Commands::*
	
	## Load plugins

	## Provide functionality to "cache" loaded plugins
	## -> evertime Module::Pluggable->plugins is called, it reloads plugins
	## -> to keep from being too much of a burden, cache the response.
	
	## Caching should be a role.  Probably useful in parser as well.
	$self->{plugins} = {};
	foreach my $plugin (qw/LS::Command::Example/) {
		my $pluginObj = ${plugin}->new();
		#$plugins->{$pluginObj->{command}} = $pluginObj;
	}
}

sub plugins {
	#$self->{} = 
}

__PACKAGE__->meta->make_immutable;
no Mouse;
1;
