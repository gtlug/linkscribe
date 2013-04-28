package LS::Parser;
use Mouse::Role;

use strict;
use warnings;


sub parse {
	LS::Exception::NotImplemented->throw();
}

no Mouse::Role;
1;
