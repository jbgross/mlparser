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

	# merge lines ending in equals signs
	$msg =~ s/[^=]=\n//g;

	# strip any other address in <>
	$msg =~ s/\<[\w\._\-]+\@[\w\.]+\>//g;

	# strip message-id
	$msg =~ s/Message\-ID.*//g;

	# strip html, except http
	$msg =~  s/\<[^htp]{4}.*\>//sg;

	# strip encoding
	$msg =~ s/(Content-Transfer-Encoding)[\w\+\/\n]+--/$1/gs;

	$self->parseDate();
	$self->parseInstitutionName();
}

# return reply-to
sub replyTo {
	my $self = shift;
	return $replyto;
}

# return domain
sub domain {
	my $self = shift;
	return $domain;
}

# return the name of the organization
sub organization {
	my $self = shift;
	return $organization;
}

# return the year of the post
sub year {
	my $self = shift;
	return $year;
}

# return the month of the post
sub month {
	my $self = shift;
	return $month;
}

# parse the reply-to email address
sub parseReplyTo {
	my $self = shift;
	my $chars = '[\w\-\.\_]';
	my $namechars = '[\w\s\,\-\.\"]';
	if($msg =~ m/[^In-]Reply-To:$namechars+\<($chars+\@($chars*))\>/) {
		# name & angle brackets
		#print "first\n";
		$replyto = lc $1;
		$domain = lc $2;
	
	} elsif ($msg =~ m/[^In-]Reply-To:\s+($chars+\@($chars+))/) {
		# no name & angle brackets
		#print "second\n";
		$replyto = lc $1;
		$domain = lc $2;
	} else {
		print "No Reply-To in msg\n";
	}
}

# parse the date of the message
sub parseDate () {
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

	} elsif ($msg =~ m/(Date.*\n)/) {
		print "date mismatch: $1";
		return ("NA", "NA");
	}
}

# get the name of the institution
sub parseInstitutionName {
	# strip out colleges within schools and some other stuff
	$msg =~ s/(faculty|college) of (arts|informatics|engineering|computing|comm|sci)\w*//ig;
	# $msg =~ s/\d+ \w+ (street|avenue|boulevard|st|ave|blvd)\.?//ig;
	# $msg =~ s/department of computer science//ig;
	# $msg =~ s/fine arts//ig;
	# $msg =~ s/computing//ig;
	# $msg =~ s/computer science department//ig;
	# $msg =~ s/professor//ig;
	# $msg =~ s/positions?//ig;
	# $msg =~ s/(^| )cs //ig;

	# this creates problems
	#if ($msg =~ m/((The )?Association (of|for)(\s\w+)+)/i
	my $last = 0;
	my $count = 0;

	# loop until we find the last one
	#while(1) {
		my $org = "";
		$count++;
		my $schoolword = '([a-zA-Z]+|St\.)';
		# splits are spaces, commas, dashes, of, or at 
		my $split = '[ \&\,\-ofat]+';

		if ($msg =~ /(($schoolword$split){1,3}(College|University))/) {
			# look for "X College" or "X University", etc.
			$org = $1;
			#print "first pattern $count - $org\n";
		} elsif ($msg =~ /((College|University)($split$schoolword){1,3})/) {
			# look for "College of X" or "University of X", etc.
			$org = $1;
			#print "second pattern $count - $org\n";
		#} else {
			## no more matches
			#last;
		}

		print "$domain - $org \n";

		$org =~ s/^[a-z0-9]* //;
		$org =~ s/ (is|or) .*//;
		$org =~ s/^(is|at|and) //;
		$org =~ s/ (is|at|and)$//;
		$org =~ s/(.*)([\s\,\-]+$)/$1/;
		$last = (lc $org);
	#}

	$organization = $last;
}

1;
