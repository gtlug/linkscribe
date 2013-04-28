package LS::Command::Test;
use parent qw(LS::Test::Class::Base);

use LS::Command;
use Test::Most;

sub setup:Test( startup=>1 ) {
	diag("here we go.");
	is(1,1,"yup. 1 == 1");
}

sub cache:Test(2) {
	my $command = LS::Command->new();
	lives_ok { $command->setCache('test','a string')} "Successfully saved data to cache";
	is ($command->getCache('test'), 'a string', "Successfully retrieved data from cache");
}

1;
