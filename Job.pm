#!/usr/bin/perl -w
use strict;

package Job;

my $job = 0;

sub new ($) {
	my $class = shift;
	bless({}, $class); # Bestow objecthood
}

sub parse($) {
	my $self = shift;
	my $msg = shift;
	if ($msg =~ m/encouraged to apply/i) {
		$job = 1;
	} else {
		$job = 0;
	}
}

sub isJob {
	return $job;
}

1;
