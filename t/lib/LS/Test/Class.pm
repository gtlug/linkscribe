package LS::Test::Class;
use base qw(LS::Test::Class::Base);

use Test::More;
use Test::Deep;
use Test::Exception;

use strict;
use warnings;

sub import {
	no strict 'refs';
	my $caller = caller;
	
	# Test::More exports the string '$TODO', to work around this, check for 
	# exports beginning with $, if you find any, export those differently
	#
	# Adapted from Advanced Perl 2nd Edition - Page 7
	foreach my $pkg (qw/Test::More Test::Deep Test::Exception/) {
		foreach my $sym (@{"${pkg}::EXPORT"}) {
			# shortcut for the common case of no type character
			(*{"${caller}::$sym"} = \&{"${pkg}::$sym"}, next) unless $sym =~ s/^(\W)//;
			my $type = $1;
			
			*{"${caller}::$sym"} =
				$type eq '&' ? \&{"${pkg}::$sym"} :
				$type eq '$' ? \${"${pkg}::$sym"} :
				$type eq '@' ? \@{"${pkg}::$sym"} :
				$type eq '%' ? \%{"${pkg}::$sym"} :
				$type eq '*' ?  *{"${pkg}::$sym"} :
				do { require Carp; Carp::croak("Can't export symbol:$type$sym") };
		}
	}

	#export your own methods:
	#*{"${caller}::$_"} = \&{"$_"} for qw(method1 method2);
} 


1;
