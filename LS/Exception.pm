package LS::Exception;
use base 'LS::Exception::Base';
use strict;
use warnings;

use Moo::Role;

use Exception::Class (
	'LS::Exception::Insufficient' => {
		isa         => 'LS::Exception',
		description => 'Insufficient Information Provided',
		fields      => 'field',
	},
	'LS::Exception::NotImplemented' => {
		isa         => 'LS::Exception',
		description => 'Feature not yet implemented.',
	},
);

LS::Exception->Trace(1);

1;
