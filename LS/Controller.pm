package LS::Controller;
use Moo;
with 'LS::InputParser';

#with 'Throwable';

### Will use Module::Pluggable to load the plugins for LS::Command and LS::URL, etc..
## once we load plugins, we scan them for their capabilities.  

### Options for handling input: 
## Plugin informs LS::Command what it can do, how it works, etc.  Parse gets passed a
## string, determines what handles it (i.e., Command informs Parse that if string begins 
## with, say "!$botname", it handles it).

## Or - Parse asks *all* plugins if string contains something plugin needs to deal with
## We setup 'priority' levels for plugins, plugins get called in order and, once finished,
## can tell Parse if it should continue on to next plugin.

## URLS are currently located via: my @urls = URI::Find::Rule->in($data,true);
## If URLs are managed via a LS::URL module (or whatever name), what is the
## best way to handle informing LS::Controller of what should be done.

has botname => (
	is => 'ro',
	default => sub { 'linkscribe' },
);

#has parser => (
#	is      => 'rw',
#	handles => 'LS::InputParser',
#);


1;
