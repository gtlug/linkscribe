package LS::Test::Class::Base;
use base qw(Test::Class Class::Data::Inheritable);

use Test::More;
use Test::Deep;

#BEGIN {
#	__PACKAGE__->mk_classdata('class');
#}

sub _startup:Tests( startup ) {
	diag('Starting Tests');

	#my $test = shift;
	#( my $class = ref $test ) =~ s/::Test$//;
	#return ok 1, "$class loaded" if $class eq __PACKAGE__;
	#use_ok $class or die;
	#$test->class($class);

}

1;
