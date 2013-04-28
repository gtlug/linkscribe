package LS::Cache;
use Mouse::Role;

## Caching Role Goals:
## 	1. Provide getter / setter for cache.
## 	2. Provide 'clear cache' mechanizim? (setter?)
## 	3. Flush cache (all?)
##
##		#1 probably not needed, just use $self->{_cache} = {}
##		The role can handle 'flushing' the cache, 
##    getter / setter could provide an easy interface to it, 
## 	say a cached method, ie, $self->cached(<name>), or 
##		set with $self->cached(<name>, <data>);


## see http://search.cpan.org/~gfuji/MouseX-NativeTraits-1.09/lib/MouseX/NativeTraits/HashRef.pm
###  Not sure if this is the right way to go, or if it would be better to
###  just roll my own method.

has 'cache' => (
	traits   => ['Hash'],
	is       => 'rw',
	isa      => 'HashRef',
	default  => sub { +{} },
	handles  => {
		cacheExist   => 'exists',
		cacheKeys    => 'keys',
		getCache     => 'get',
		setCache     => 'set',
	},
);

no Mouse::Role;
1;
