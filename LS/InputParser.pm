package LS::InputParser;
use strict;
use warnings;

use Moo::Role;
with 'LS::Exception';


sub parse {
	LS::Exception::NotImplemented->throw();
}

1;
