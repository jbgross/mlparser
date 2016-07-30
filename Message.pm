#!/usr/bin/perl -w
use strict;

package Message;

our $msg = "";
our $day = 0;
our $date = 0;
our $month = 0;
our $year = 0;
our $hour = 0;
our $minute = 0;
our $second = 0;
our $timezone = 0;
our $organization = 0;
our $domain = 0;
our $contact = 0;
our $replyto = 0;

sub new($) {
	my $invocant = shift;
	my $class = ref($invocant) || $invocant;
	my $self = { @_ }; # Remaining args become attributes
	bless($self, $class); # Bestow objecthood
	return $self;
}

sub parse ($) {
	my $self = shift;
	$msg = shift;
	$self->parseReplyTo();
	$self->getDate();
	$self->getOrganization();
	$self->getDomain();
}

sub replyTo {
	my $self = shift;
	return $replyto;
}


sub domain {
	my $self = shift;
	return $domain;
}

sub organization {
	my $self = shift;
	return $organization;
}

sub year {
	my $self = shift;
	return $year;
}


sub month {
	my $self = shift;
	return $month;
}

sub parseReplyTo {
	my $self = shift;
	$msg =~ m/Reply-To:\s(.*)$/;
	$replyto = $1;
}

sub getDate () {
	#first, extract the date string
	if($msg =~ m/Date:\s+(\w{3}), (\d{1,2}) (\w{3}) (\d{4}) (\d{2}):(\d{2}):(\d{2}) (.?\d{4})/) {
		$day = $1;
		$date = $2;
		$month = $3;
		$year = $4;
		$hour = $5;
		$minute = $6;
		$second = $7;
		$timezone = $8;

		#print "$day $date $month $year $hour $minute $second $ timezone\n";
		return ($month, $year);
	} elsif ($msg =~ m/(Date.*\n)/) {
		print "date mismatch: $1";
		return ("NA", "NA");
	}
}

sub getOrganization() {
	# strip out colleges within schools and some other stuff
	$msg =~ s/(faculty|college) of (arts|informatics|engineering|computing|comm|sci)//ig;
	$msg =~ s/department of computer science//ig;
	$msg =~ s/fine arts//ig;
	$msg =~ s/computing//ig;
	$msg =~ s/computer science department//ig;
	$msg =~ s/professor//ig;
	$msg =~ s/positions?//ig;
	$msg =~ s/(^| )cs //ig;

	# this creates problems
	#if ($msg =~ m/((The )?Association (of|for)(\s\w+)+)/i
	my $last = 0;

	# loop until we find the last one
	while(1) {
		# look for "X College" or "College of X" or University, etc.
		if ($msg =~ s/((The )?[A-Z]\w+ ([\w\&]+\s)*State (College|University) ?([\w\&\-\,]+)*)//
			|| $msg =~ s/((The )?(College|University) of [A-Z]\.?\w+ ?([\w\&]+\s)*( ([\w\&\,]+))*)//
			|| $msg =~ s/((The )?[A-Z]\.?\w+ ((\w+|\&)+\s)*(College|University)( ([\w\&\-\,]+))*)//) {

			my $org = $1;
			$org =~ s/^[a-z0-9]* //;
			$org =~ s/ (is|or) .*//;
			$org =~ s/^(is|at|and) //;
			$org =~ s/ (is|at|and)$//;
			$org =~ s/(.*)([\s\,\-]+$)/$1/;
			$last = (lc $org);
		} else {
			last;
		}
	}
	$organization = $last;
}

sub getDomain($) {
	if ($msg =~ m/(\w+\.edu)\W/i || $msg =~ m/(\w+\.(com|org))/i || $msg =~ m/([\w\.]+\.(us|dk))/i) {
		$domain = (lc $1);
	}
}

1;