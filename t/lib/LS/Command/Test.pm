package LS::Command::Test;
use base qw(LS::Test::Class::Base);

use LS::Test::Class;
use LS::Command;

sub setup:Test( startup ) {
	diag("here we go.");
	
	#cmp_deeply(\@b, subbagof(@a), '@b is a subset of @a');
}

sub cache:Test(2) {
	my $self = shift;
	
	my $command = LS::Command->new();
	lives_ok { $command->setCache('test','a string')} "Successfully saved data to cache";
	is ($command->getCache('test'), 'a string', "Successfully retrieved data from cache");
}

#sub getPlugins:Test(1) {
#	my $self = shift;
	
	#my $command = LS::Command->new();
	
	#my $plugins = $command->refreshPlugins();
#}

1;
