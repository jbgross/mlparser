#!/usr/bin/perl -w
use strict;

my $linecount = 0;
my $filecount = 0;

for my $file (@ARGV) {
	open (FILE, "<", $file) or die "Can't open $file for reading: $!";
	$filecount++;
	for my $line (<FILE>) {
		$linecount++
	}
	close FILE;
}

print "$linecount total lines in $filecount files\n";
