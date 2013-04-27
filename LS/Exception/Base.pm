package LS::Exception::Base;
use base 'Exception::Class::Base';

sub new {
	my $class = shift;
	my $self = $class->SUPER::new(@_);
}

sub throw {
	my ($self, @args) = @_;
	
	warn "Exception $self thrown";
	
	$self->SUPER::throw(@_);
}

1;

