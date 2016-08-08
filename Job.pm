#!/usr/bin/perl -w
use strict;

package Job;

our $job = 0;

sub new ($) {
	my $invocant = shift;
	my $class = ref($invocant) || $invocant;
	my $self = { @_ }; # Remaining args become attributes
	bless($self, $class); # Bestow objecthood
	return $self;
}

sub parse($) {
	my $self = shift;
	my $msg = shift;
	if ($msg =~ m/encouraged to apply/i) {
		$job = 1;
	}
}

sub isJob {
	return $job;
}

1;
