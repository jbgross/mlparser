#!/usr/bin/perl -w
use strict;
use DBI;

package Message;

my $msg = "";
my $day = 0;
my $date = 0;
my $month = 0;
my $year = 0;
# this is the year that the academic year starts in - e.g., Oct 2012 is 2012, and Feb 2013 is 2012
my $academicyear = 0;
my $organization = 0;
my $domain = 0;
my $contact = 0;
my $contactaddress = 0;
my $fname = "";
my $lname = "";
my $subject = 0;
my $body = "";
my $filename = "";

sub new($) {
	#my $invocant = shift;
	#my $class = ref($invocant) || $invocant;
	#my $self = { @_  }; # Remaining args become attributes

	my $class = shift;
	bless({}, $class); # Bestow objecthood
}

sub parse ($$) {
	my $self = shift;
	$msg = shift;
	$filename = shift;

	# merge lines - doesn't work, might not need it
	#$msg =~ s/\n^\s+(\w.*)\n/$1/g;

	$self->parseContact();
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
	
	$self->parseBody();
}

sub firstName {
	my $self = shift;
	return $fname;
}

sub lastName {
	my $self = shift;
	return $lname;
}

	
sub subject {
	my $self = shift;
	return $subject;
}

# return contact address
sub contactAddress{
	my $self = shift;
	return $contactaddress;
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
	if ($msg =~ m/Subject:\s+(.*)/) {
		$subject = $1;
	} else {
		print "no subject from email from $contactaddress on in $month, $year in $filename\n";
	}
}

# parse the subject line
sub parseBody {
	#print "??".substr($msg, 0, 300)."??\n";

	my $self = shift;
	my $last = "";

	# this isn't stripping some of the headers and I don't know why
	while ($msg =~ s/^((([\w\-])*):\s.*)\n//) {
		$last = $1;
	}

	#print "last matched - $last\n||".substr($msg, 0, 25)."||\n";
	# merge lines
	$msg =~ s/\n/ /g;
	$msg =~ s/^\s+//;
	$body = $msg;
}

# parse the contact email address
sub parseContact {
	my $self = shift;
	my $chars = '[\w\-\.\_\?\=\+]';
	my $namechars = '[\w\s\,\-\.\"\'\(\)\?\=\+\@\/\\\!]';
	my $namecharssimple = '[\w\-\.\']';

	# don't know why, but I need to reset this
	$contactaddress = "";

	# strip the threading, messes with below
	$msg =~ s/In-Reply.*//g;

	# if the name is before the email address, which is in angle brackets, for either Reply-To or From fields
	if($msg =~ m/(Reply-To:($namechars+)\n?\s+\<($chars+\@($chars+))\>)/
		|| $msg =~ m/(From:($namechars+)\n?\s+\<($chars+\@($chars+))\>)/) {
		# name & angle brackets
		$contactaddress = lc $3;
		$domain = lc $4;
		my $name = $2;
		my $line = $1;
		$name =~ s/[\-\.\"\(\)\?\=\+\@\/\\\!]//g;
		$name =~ s/^\s*//;
		#print "$name\n";
		if ($name =~ m/($namecharssimple+),\s*($namecharssimple+)/) {
			$fname = $2;
			$lname = $1;
			#print "$fname - $lname\n";
		} elsif ($name =~ m/($namecharssimple+).*\s($namecharssimple+)/) {
			$fname = $1;
			$lname = $2;
			#print "$fname - $lname\n";
		} else {
			$fname = $name;
			$lname = "";
		}
	
		
	} elsif ($msg =~ m/Reply-To:\s+($chars+\@($chars+))/ 
		|| $msg =~ m/From:\s+($chars+\@($chars+))/) {
		# no name & angle brackets
		$contactaddress = lc $1;
		$domain = lc $2;
		$fname = "";
		$lname = "";
	} else {
		print "No Reply-To or From in msg $msg\n";
		$contactaddress = "0";
	}
	$domain =~ s/.*\.(.*\.edu)/$1/i;
}

# parse the date of the message
sub parseDate () {
	#first, extract the date string
	if($msg =~ m/Date:\s+(\w{3}),\s+(\d{1,2})\s+(\w{3})\s+(\d{4})/) {
		$day = $1;
		$date = $2;
		$month = $3;
		$year = $4;
		if($month =~ m/(Jan|Feb|Mar|Apr|May|Jun)/) {
			$academicyear = $year-1;
		} elsif ($month =~ m/(Jul|Aug|Sep|Oct|Nov|Dec)/) {
			$academicyear = $year-1;
		} else {
			warn "Can't match month $month\n";
		}

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

	#if($contactaddress eq 'fredm@cs.uml.edu') { print "msg\n$msg\n\n"; }

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
	#$organization = (lc $org);
	$organization = $org;
}

sub addToDatabase {
	my $self = shift;
	my $dbh = shift;
	my $ciid = ""; # candidate institution id
	my $ccid = ""; # candidate contact id

	# insert candidate institution information
	eval {

		my $candInstInsert = "INSERT INTO candidateinstitution (DOMAIN, NAME) values (?, ?)";
		my $sth = $dbh->prepare($candInstInsert);
		$sth->bind_param(1, $domain, $DBI::SQL_VARCHAR);
		$sth->bind_param(2, $organization, $DBI::SQL_VARCHAR);
		
		$sth->execute();

		# can't use last_insert_id since repeats are ignored
		my $candIdSelect = "SELECT candidateinstitutionid from candidateinstitution where domain = ? and name = ?";
		$sth = $dbh->prepare($candIdSelect);
		$sth->bind_param(1, $domain, $DBI::SQL_VARCHAR);
		$sth->bind_param(2, $organization, $DBI::SQL_VARCHAR);
		$sth->execute();

		my $ref = $sth->fetchall_arrayref();
		if (scalar @$ref != 1) {
			warn "No or multiple matching candidateinstitutionid for $domain, $organization.\n";
			return;
		} else {
			$ciid = (@$ref->[0])->[0];
			#print "The correct id of the inserted candidateinstitution row is $ciid\n";
		}
		
		$dbh->commit();
	};

	if ($@) {
		warn "Database error inserting candidateinstitution ($domain, $organization): $DBI::errstr";
		$dbh->rollback();
	}

	# insert candidate contact information
	eval {

		my $candidateContactInsert = "INSERT INTO candidatecontact (ADDRESS, FIRSTNAME, LASTNAME) values (?, ?, ?)";
		my $sth = $dbh->prepare($candidateContactInsert);
		$sth->bind_param(1, $contactaddress, $DBI::SQL_VARCHAR);
		$sth->bind_param(2, $fname, $DBI::SQL_VARCHAR);
		$sth->bind_param(3, $lname, $DBI::SQL_VARCHAR);
		
		$sth->execute();

		# can't use last_insert_id since repeats are ignored
		my $candIdSelect = "SELECT candidatecontactid from candidatecontact where address= ? and firstname = ? and lastname = ?";
		$sth = $dbh->prepare($candIdSelect);
		$sth->bind_param(1, $contactaddress, $DBI::SQL_VARCHAR);
		$sth->bind_param(2, $fname, $DBI::SQL_VARCHAR);
		$sth->bind_param(3, $lname, $DBI::SQL_VARCHAR);

		$sth->execute();

		my $ref = $sth->fetchall_arrayref();
		if (scalar @$ref != 1) {
			warn "No or multiple matching candidatecontactid for $contactaddress, $fname, $lname\n";
			return;
		} else {
			$ccid = (@$ref->[0])->[0];
			#print "The correct id of the inserted candidatecontact row is $ccid\n";
		}
		
		$dbh->commit();
	};

	if ($@) {
		warn "Database error inserting candidatecontact ($contactaddress, $fname, $lname): $DBI::errstr";
		$dbh->rollback();
	}

	# insert message information
	eval {

		my $candContactInsert = "INSERT INTO message "
			."(candidatecontactid, candidateinstitutionid, subject, body, year, month, academicyear, filename) "
			." values (?, ?, ?, ?, ?, ?, ?, ?)";
		my $sth = $dbh->prepare($candContactInsert);
		$sth->bind_param(1, $ccid, $DBI::SQL_INTEGER);
		$sth->bind_param(2, $ciid, $DBI::SQL_INTEGER);
		$sth->bind_param(3, $subject, $DBI::SQL_VARCHAR);
		$sth->bind_param(4, $body, $DBI::SQL_VARCHAR);
		$sth->bind_param(5, $year, $DBI::SQL_INTEGER);
		$sth->bind_param(6, $month, $DBI::SQL_INTEGER);
		$sth->bind_param(7, $academicyear, $DBI::SQL_INTEGER);
		$sth->bind_param(8, $filename, $DBI::SQL_VARCHAR);
		
		$sth->execute();
		my $id = $dbh->last_insert_id("", "", "message", "");
		#print "The last Id of the inserted row is $id\n";
		$dbh->commit();
	};

	if ($@) {
		warn "Database error inserting candidatecontact ($contactaddress, $fname, $lname): $DBI::errstr";
		$dbh->rollback();
	}
}

1;
