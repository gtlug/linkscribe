package LS::Command;
use Mouse;
with qw(LS::Base LS::Cache);

sub getPlugins {
	my $self = shift;
	## Find all plugins in LS::Commands::*
	
	## Load plugins

	## Provide functionality to "cache" loaded plugins
	## -> evertime Module::Pluggable->plugins is called, it reloads plugins
	## -> to keep from being too much of a burden, cache the response.
	
	## Caching should be a role.  Probably useful in parser as well.
}

__PACKAGE__->meta->make_immutable;
no Mouse;
1;
