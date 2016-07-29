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
			my $domain = &getDomain($msg);
			if ($domain eq "0") {
				# we have a problem, no domain
				$orgs{"error - no org in message # $msginfilecount"} = $file;
			} else {
				$orgs{$domain} = $org;
			}

		}
		close FILE;
		$msginfilecount = 0;
	}

	&printOrgs(%orgs);

	print scalar(keys %orgs)." different organizations\n";

	$msgcount--;
	print "$msgcount total messages in $filecount files\n";
}

sub printOrgs (%) {
	my %orgs = @_;
	for my $key(sort keys %orgs) {
		print "$key - $orgs{$key}\n";
	}
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
	# strip out colleges within schools
	$msg =~ s/(faculty|college) of (arts|informatics|engineering|computing|comm|sci)//ig;
	$msg =~ s/department of computer science//ig;
	$msg =~ s/computer science department//ig;

	if ($msg =~ m/((The )?Association (of|for)(\s\w+)+)/i
		|| $msg =~ m/((The )?[A-Z]\w+ ([\w\&]+\s)*State (College|University) ?([\w\&\-\,]+)*)/
		|| $msg =~ m/((The )?(College|University) of [A-Z]\.\w+ ?([\w\&]+\s)* ?([\w\&\-\,]+)*)/
		|| $msg =~ m/((The )?[A-Z]\.\w+ ((\w+|\&)+\s)*(College|University) ?([\w\&\-\,]+)*)/) {

		my $org = $1;
		$org =~ s/(.*)([\s\,\-]+$)/$1/;
		return (lc $org);
	}
	return 0;
}

sub getDomain($) {
	my ($msg) = @_;
	if ($msg =~ m/([\w]+\.(com|org|edu))/i || $msg =~ m/([\w\.]+\.(us|dk))/i) {
		return (lc $1);
	}
	return 0;
}


&main();
