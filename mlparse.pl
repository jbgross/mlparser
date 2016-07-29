#!/usr/bin/perl -w
use strict;


sub main {
	# make line separator the row of == signs
	$/="=========================================================================";
	
	my $msginfilecount = 0;
	my $msgcount = 0;
	my $filecount = 0;
	
	my %orgs;
	# now loop through the each file in the ARGV list
	for my $file (@ARGV) {
		open (FILE, "<", $file) or die "Can't open $file for reading: $!";
		$filecount++;
		my $msg = "";
		for $msg(<FILE>) {
			$msgcount++;
			$msginfilecount++;
	
			# ignore the 1st "message", since it's just the top row
			if ($msginfilecount == 1) {
				next;
			}
			my ($month, $year) = &getDate($msg);
			my $org = &getOrganization($msg);
			$orgs{$org} = $file;

		}
		close FILE;
		$msginfilecount = 0;
	}


	for my $key(sort keys %orgs) {
		print "$key $orgs{$key}\n";
	}

	print scalar(keys %orgs)." different organizations\n";

	$msgcount--;
	print "$msgcount total lines in $filecount files\n";
}

sub isJob($) {
	my ($msg) = @_;
}

sub getDate ($) {
	my ($msg) = @_;
	#first, extract the date string
	if($msg =~ m/Date:\s+(\w{3}), (\d{1,2}) (\w{3}) (\d{4}) (\d{2}):(\d{2}):(\d{2}) (.?\d{4})/) {
		my $day = $1;
		my $date = $2;
		my $month = $3;
		my $year = $4;
		my $hour = $5;
		my $minute = $6;
		my $second = $7;
		my $timezone = $8;

		#print "$day $date $month $year $hour $minute $second $ timezone\n";
		return ($month, $year);
	} elsif ($msg =~ m/(Date.*\n)/) {
		print "date mismatch: $1";
		return ("NA", "NA");
	}
}

sub getOrganization($) {
	my ($msg) = @_;
	# look for "X College" or College of X
	if ($msg =~ m/((The )?Association(\s\w+)+)/i
		|| $msg =~ m/((The )?[A-Z]\w+ ([\w\&]+\s)*State (College|University) ?([\w\&\-\,]+)*)/
		|| $msg =~ m/((The )?(College|University) of [A-Z]\w+ ?([\w\&]+\s)* ?([\w\&\-\,]+)*)/
		|| $msg =~ m/((The )?[A-Z]\w+ ((\w+|\&)+\s)*(College|University) ?([\w\&\-\,]+)*)/
		|| $msg =~ m/([\w\.]+(com|org|edu|us|dk))/i) {
		my $org = $1;
		$org =~ s/(.*)([\s\,]+$)/$1/;
		return (lc $org);
	}
	print $msg."\n";
	return "no organization found";
}
&main();
