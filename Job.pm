#!/usr/bin/perl -w
use strict;

package Job;

our $job = 0;

sub new ($) {
	my ($msg) = @_;
	if ($msg =~ m/encouraged to apply/i) {
		$job = 1;
	}
}

sub isJob {
	return $job;
}

1;
