#!/usr/bin/perl -w
use strict;

package Message;

my $msg = "";
my $day = 0;
my $date = 0;
my $month = 0;
my $year = 0;
my $organization = 0;
my $domain = 0;
my $contact = 0;
my $replyto = 0;
my $subject = 0;

sub new($) {
	#my $invocant = shift;
	#my $class = ref($invocant) || $invocant;
	#my $self = { @_  }; # Remaining args become attributes

	my $class = shift;
	bless({}, $class); # Bestow objecthood
}

sub parse ($) {
	my $self = shift;

	$msg = shift;
	$self->parseReplyTo();
	$self->parseSubject();

	# merge lines ending in equals signs
	$msg =~ s/[^=]=\n//g;

	# strip any other address in <>
	$msg =~ s/\<[\w\._\-]+\@[\w\.]+\>//g;


	# strip message-id
	$msg =~ s/Message\-ID.*//g;

	# strip html (but not content between tags)
	$msg =~  s/\<[^\<\>]*\>//sg;

	# strip encoding
	$msg =~ s/(Content-Transfer-Encoding: base64)[\w\+\/\n]+--/$1/gs;

	$self->parseDate();
	$self->parseInstitutionName();
}

sub subject {
	my $self = shift;
	return $subject;
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

# return the message text of the post
sub message {
	my $self = shift;
	return $msg;
}

# parse the subject line
sub parseSubject {
	my $self = shift;
	if ($msg =~ m/Subject:\s(.*)/) {
		$subject = $1
	} else {
		print "no subject $replyto\n";
	}
}

# parse the reply-to email address
sub parseReplyTo {
	my $self = shift;
	my $chars = '[\w\-\.\_\?\=\+]';
	my $namechars = '[\w\s\,\-\.\"\'\(\)\?\=\+\@\/\\\!]';

	# don't know why, but I need to reset this
	# $replyto = 0;

	if($msg =~ m/[^In-]*Reply-To:$namechars+\n?\s+\<($chars+\@($chars+))\>/) {
		# name & angle brackets
		#print "first\n";
		$replyto = lc $1;
		$domain = lc $2;
	
	} elsif ($msg =~ m/[^In-]*Reply-To:\s+($chars+\@($chars+))/) {
		# no name & angle brackets
		#print "second\n";
		$replyto = lc $1;
		$domain = lc $2;
	} else {
		print "No Reply-To in msg $msg\n";
		$replyto = "0";
	}
	$domain =~ s/.*\.(.*\.edu)/$1/i;
}

# parse the date of the message
sub parseDate () {
	#first, extract the date string
	#if($msg =~ m/Date:\s+(\w{3}), (\d{1,2}) (\w{3}) (\d{4}) (\d{2}):(\d{2}):(\d{2}) (.?\d{4})/) {
	if($msg =~ m/Date:\s+(\w{3}),\s+(\d{1,2})\s+(\w{3})\s+(\d{4})/) {
		$day = $1;
		$date = $2;
		$month = $3;
		$year = $4;

	} elsif ($msg =~ m/(Date.*\n)/) {
		print "date mismatch: $1";
		return ("NA", "NA");
	}
}

# get the name of the institution
sub parseInstitutionName {

	# strip out colleges within schools and some other stuff
	$msg =~ s/(faculty|college) of? (arts|informatics|engineering|computing|comm|sci)\w*//ig;
	$msg =~ s/(the (college|university))/$2/ig;

	# $msg =~ s/\d+ \w+ (street|avenue|boulevard|st|ave|blvd)\.?//ig;
	$msg =~ s/computer science department//ig;
	$msg =~ s/department of computer science//ig;
	# $msg =~ s/fine arts//ig;
	# $msg =~ s/computing//ig;
	# $msg =~ s/professor//ig;
	# $msg =~ s/positions?//ig;
	# $msg =~ s/(^| )cs //ig;

	# this creates problems
	#if ($msg =~ m/((The )?Association (of|for)(\s\w+)+)/i

	my $org = "";
	my $schoolword = '([a-zA-Z]+|St\.)';
	# splits are spaces, commas, dashes, of, or at 
	my $splitBefore = '[ \&ofat]+';
	my $splitAfter = '[ \&\,\-ofat]+';

	#if($replyto eq 'fredm@cs.uml.edu') { print "msg\n$msg\n\n"; }

	if ($msg =~ /(($schoolword$splitBefore){1,3}(College|University))/) {
		# look for "X College" or "X University", etc.
		$org = $1;
		#print "first pattern - $org\n";
	} elsif ($msg =~ /((College|University)($splitAfter$schoolword){1,3})/) {
		# look for "College of X" or "University of X", etc.
		$org = $1;
		#print "second pattern - $org\n";
	# only for debugging
	# } else {
	#	print "no school!\n";
	}

	#print "$domain - $org \n";

	$org =~ s/^[a-z0-9]* //;
	$org =~ s/ (is|or) .*//;
	$org =~ s/^(is|at|and) //;
	$org =~ s/ (is|at|and)$//;
	$org =~ s/(.*)([\s\,\-]+$)/$1/;
	$organization = (lc $org);
}

1;
