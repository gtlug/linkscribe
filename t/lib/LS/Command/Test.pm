package LS::Command::Test;
use base qw(LS::Test::Class::Base);

use LS::Test::Class;
use LS::Command;

sub setup:Test( startup=>1 ) {
	diag("here we go.");
	is(1,1,"yup. 1 == 1");
}

sub cache:Test(3) {
	my $command = LS::Command->new();
	lives_ok { $command->setCache('test','a string')} "Successfully saved data to cache";
	is ($command->getCache('test'), 'a string', "Successfully retrieved data from cache");
	my @a = ('a', 'b', 'c', 'd');
	my @b = ('b', 'd');
	cmp_deeply(\@b, subbagof(@a), '@b is a subset of @a');
}

1;
