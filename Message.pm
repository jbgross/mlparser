#!/usr/bin/perl -w
use strict;
use DBI;

package Message;

sub new($) {
	#my $invocant = shift;
	#my $class = ref($invocant) || $invocant;
	my $self = { };

	my $class = shift;

	# set up attributes
	$self->{messagetext} = "";
	$self->{date} = 0;
	$self->{month} = 0;
	$self->{year} = 0;
	# this is the year that the academic year starts in - e.g., Oct 2012 is 2012, and Feb 2013 is 2012
	$self->{academicyear} = 0;
	$self->{isjob} = 0;
	$self->{organization} = "";
	$self->{domain} = "";
	$self->{contactaddress} = "";
	$self->{firstname} = "";
	$self->{lastname} = "";
	$self->{subject} = "";
	$self->{messagebody} = "";
	$self->{filename} = "";

	bless($self, $class); # Bestow objecthood
}

sub parse ($$$) {
	my $self = shift;
	$self->{messagetext} = shift;
	$self->{filename} = shift;

	# merge lines - doesn't work, might not need it
	#$self->{messagetext} =~ s/\n^\s+(\w.*)\n/$1/g;

	$self->parseContact();
	$self->parseSubject();

	# merge lines ending in equals signs
	$self->{messagetext} =~ s/[^=]=\n//g;

	# strip any other address in <>
	$self->{messagetext} =~ s/\<[\w\._\-]+\@[\w\.]+\>//g;


	# strip message-id
	$self->{messagetext} =~ s/Message\-ID.*//g;

	# strip html (but not content between tags)
	$self->{messagetext} =~  s/\<[^\<\>]*\>//sg;

	# strip encoding
	$self->{messagetext} =~ s/(Content-Transfer-Encoding: base64)[\w\+\/\n]+--/$1/gs;

	$self->parseDate();
	$self->parseInstitutionName();
	
	$self->parseBody();
}

# pass in anything other than a 0 to set this to true
sub setJob {
	my $self = shift;
	if(shift ne "0") {
		$self->{isjob} = 1;
	}
}

sub firstName {
	my $self = shift;
	return $self->{firstname};
}

sub lastName {
	my $self = shift;
	return $self->{lastname};
}

	
sub subject {
	my $self = shift;
	return $self->{subject};
}

# return contact address
sub contactAddress{
	my $self = shift;
	return $self->{contactaddress};
}

# return domain
sub domain {
	my $self = shift;
	return $self->{domain};
}

# return the name of the organization
sub organization {
	my $self = shift;
	return $self->{organization};
}

# return the year of the post
sub year {
	my $self = shift;
	return $self->{year};;
}

# return the month of the post
sub month {
	my $self = shift;
	return $self->{month};
}

# return the message text of the post
sub messageBody {
	my $self = shift;
	return $self->{messagebody};
}

# return the message text of the post
sub messageText {
	my $self = shift;
	return $self->{messagetext};
}

# parse the subject line
sub parseSubject {
	my $self = shift;
	if ($self->{messagetext} =~ m/Subject:\s+(.*)/) {
		$self->{subject} = $1;
	} else {
		print "no subject from email from $self->{contactaddress} on in $self->{month}, $self->{year} in $self->{filename}\n";
	}
}

# parse the subject line
sub parseBody {
	#print "??".substr($self->{messagetext}, 0, 300)."??\n";

	my $self = shift;
	my $last = "";

	# this isn't stripping some of the headers and I don't know why
	while ($self->{messagetext} =~ s/^((([\w\-])*):\s.*)\n//) {
		$last = $1;
	}

	#print "last matched - $last\n||".substr($self->{messagetext}, 0, 25)."||\n";
	# merge lines
	$self->{messagetext} =~ s/\n/ /g;
	$self->{messagetext} =~ s/^\s+//;
	$self->{messagebody} = $self->{messagetext};
}

# parse the contact email address
sub parseContact {
	my $self = shift;
	my $chars = '[\w\-\.\_\?\=\+]';
	my $namechars = '[\w\s\,\-\.\"\'\(\)\?\=\+\@\/\\\!]';
	my $namecharssimple = '[\w\-\.\']';

	# strip the threading, messes with below
	$self->{messagetext} =~ s/In-Reply.*//g;

	# if the name is before the email address, which is in angle brackets, for either Reply-To or From fields
	if($self->{messagetext} =~ m/(Reply-To:($namechars+)\n?\s+\<($chars+\@($chars+))\>)/
		|| $self->{messagetext} =~ m/(From:($namechars+)\n?\s+\<($chars+\@($chars+))\>)/) {
		# name & angle brackets
		$self->{contactaddress} = lc $3;
		$self->{domain} = lc $4;
		my $name = $2;
		my $line = $1;
		$name =~ s/[\-\.\"\(\)\?\=\+\@\/\\\!]//g;
		$name =~ s/^\s*//;
		#print "$name\n";
		if ($name =~ m/($namecharssimple+),\s*($namecharssimple+)/) {
			$self->{firstname} = $1;
			$self->{lastname} = $2;
		} elsif ($name =~ m/($namecharssimple+).*\s($namecharssimple+)/) {
			$self->{lastname} = $1;
			$self->{firstname} = $2;
		} else {
			$self->{firstname} = $name;
			$self->{lastname} = "";
		}
	
		
	} elsif ($self->{messagetext} =~ m/Reply-To:\s+($chars+\@($chars+))/ 
		|| $self->{messagetext} =~ m/From:\s+($chars+\@($chars+))/) {
		# no name & angle brackets
		$self->{contactaddress} = lc $1;
		$self->{domain} = lc $2;
		$self->{firstname} = "";
		$self->{lastname}  = "";
	} else {
		warn "No Reply-To or From in msg ". substr($self->{messagetext},0,25)."in file $self-{filename}\n";
	}
	$self->{domain} =~ s/.*\.(.*\.edu)/$1/i;
}

# parse the date of the message
sub parseDate () {
	my $self = shift;
	#first, extract the date string
	if($self->{messagetext} =~ m/Date:\s+(\w{3}),\s+(\d{1,2})\s+(\w{3})\s+(\d{4})/) {
		$self->{day} = $1;
		$self->{date} = $2;
		$self->{month} = $3;
		$self->{year} = $4;
		if($self->{month} =~ m/(Jan|Feb|Mar|Apr|May|Jun)/) {
			$self->{academicyear} = $self->{year}-1;
		} elsif ($self->{month} =~ m/(Jul|Aug|Sep|Oct|Nov|Dec)/) {
			$self->{academicyear} = $self->{year}-1;
		} else {
			warn "Can't match month $self->{month}\n";
		}

	} elsif ($self->{messagetext} =~ m/(Date.*\n)/) {
		print "date mismatch: $1";
		return ("NA", "NA");
	}
}

# get the name of the institution
sub parseInstitutionName {
	my $self = shift;

	# strip out colleges within schools and some other stuff
	$self->{messagetext} =~ s/(faculty|college) of? (arts|informatics|engineering|computing|comm|sci)\w*//ig;
	$self->{messagetext} =~ s/(the (college|university))/$2/ig;

	# $self->{messagetext} =~ s/\d+ \w+ (street|avenue|boulevard|st|ave|blvd)\.?//ig;
	$self->{messagetext} =~ s/computer science department//ig;
	$self->{messagetext} =~ s/department of computer science//ig;
	# $self->{messagetext} =~ s/fine arts//ig;
	# $self->{messagetext} =~ s/computing//ig;
	# $self->{messagetext} =~ s/professor//ig;
	# $self->{messagetext} =~ s/positions?//ig;
	# $self->{messagetext} =~ s/(^| )cs //ig;

	# this creates problems
	#if ($self->{messagetext} =~ m/((The )?Association (of|for)(\s\w+)+)/i

	my $org = "";
	my $schoolword = '([a-zA-Z]+|St\.)';
	# splits are spaces, commas, dashes, of, or at 
	my $splitBefore = '[ \&ofat]+';
	my $splitAfter = '[ \&\,\-ofat]+';

	if ($self->{messagetext} =~ /(($schoolword$splitBefore){1,3}(College|University))/) {
		# look for "X College" or "X University", etc.
		$org = $1;
		#print "first pattern - $org\n";
	} elsif ($self->{messagetext} =~ /((College|University)($splitAfter$schoolword){1,3})/) {
		# look for "College of X" or "University of X", etc.
		$org = $1;
		#print "second pattern - $org\n";
	# only for debugging
	# } else {
	#	print "no school!\n";
	}

	$org =~ s/^[a-z0-9]* //;
	$org =~ s/ (is|or) .*//;
	$org =~ s/^(is|at|and) //;
	$org =~ s/ (is|at|and)$//;
	$org =~ s/(.*)([\s\,\-]+$)/$1/;
	#$self->{organization} = (lc $org);
	$self->{organization} = $org;
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
		$sth->bind_param(1, $self->{domain}, $DBI::SQL_VARCHAR);
		$sth->bind_param(2, $self->{organization}, $DBI::SQL_VARCHAR);
		
		$sth->execute();

		# can't use last_insert_id since repeats are ignored
		my $candIdSelect = "SELECT candidateinstitutionid from candidateinstitution where domain = ? and name = ?";
		$sth = $dbh->prepare($candIdSelect);
		$sth->bind_param(1, $self->{domain}, $DBI::SQL_VARCHAR);
		$sth->bind_param(2, $self->{organization}, $DBI::SQL_VARCHAR);
		$sth->execute();

		my $ref = $sth->fetchall_arrayref();
		if (scalar @$ref != 1) {
			warn "No or multiple matching candidateinstitutionid for $self->{domain}, $self->{organization}.\n";
			return;
		} else {
			$ciid = (@$ref->[0])->[0];
			#print "The correct id of the inserted candidateinstitution row is $ciid\n";
		}
		
		$dbh->commit();
	};

	if ($@) {
		warn "Database error inserting candidateinstitution ($self->{domain}, $self->{organization}): $DBI::errstr";
		$dbh->rollback();
	}

	# insert candidate contact information
	eval {

		my $candidateContactInsert = "INSERT INTO candidatecontact (ADDRESS, FIRSTNAME, LASTNAME) values (?, ?, ?)";
		my $sth = $dbh->prepare($candidateContactInsert);
		$sth->bind_param(1, $self->{contactaddress}, $DBI::SQL_VARCHAR);
		$sth->bind_param(2, $self->{firstname}, $DBI::SQL_VARCHAR);
		$sth->bind_param(3, $self->{lastname}, $DBI::SQL_VARCHAR);
		
		$sth->execute();

		# can't use last_insert_id since repeats are ignored
		my $candIdSelect = "SELECT candidatecontactid from candidatecontact where address= ? and firstname = ? and lastname = ?";
		$sth = $dbh->prepare($candIdSelect);
		$sth->bind_param(1, $self->{contactaddress}, $DBI::SQL_VARCHAR);
		$sth->bind_param(2, $self->{firstname}, $DBI::SQL_VARCHAR);
		$sth->bind_param(3, $self->{lastname}, $DBI::SQL_VARCHAR);

		$sth->execute();

		my $ref = $sth->fetchall_arrayref();
		if (scalar @$ref != 1) {
			warn "No or multiple matching candidatecontactid for $self->{contactaddress}, $self->{firstname}, $self->{lastname}\n";
			return;
		} else {
			$ccid = (@$ref->[0])->[0];
			#print "The correct id of the inserted candidatecontact row is $ccid\n";
		}
		
		$dbh->commit();
	};

	if ($@) {
		warn "Database error inserting candidatecontact ($self->{contactaddress}, $self->{firstname}, $self->{lastname}): $DBI::errstr";
		$dbh->rollback();
	}

	# insert message information
	eval {

		my $candContactInsert = "INSERT INTO message "
			."(candidatecontactid, candidateinstitutionid, subject, body, year, month, academicyear, filename, isjob) "
			." values (?, ?, ?, ?, ?, ?, ?, ?, ?)";
		my $sth = $dbh->prepare($candContactInsert);
		$sth->bind_param(1, $ccid, $DBI::SQL_INTEGER);
		$sth->bind_param(2, $ciid, $DBI::SQL_INTEGER);
		$sth->bind_param(3, $self->{subject}, $DBI::SQL_VARCHAR);
		$sth->bind_param(4, $self->{messagebody}, $DBI::SQL_VARCHAR);
		$sth->bind_param(5, $self->{year}, $DBI::SQL_INTEGER);
		$sth->bind_param(6, $self->{month}, $DBI::SQL_INTEGER);
		$sth->bind_param(7, $self->{academicyear}, $DBI::SQL_INTEGER);
		$sth->bind_param(8, $self->{filename}, $DBI::SQL_VARCHAR);
		$sth->bind_param(9, $self->{isjob}, $DBI::SQL_INTEGER);
		
		$sth->execute();
		my $id = $dbh->last_insert_id("", "", "message", "");
		#print "The last Id of the inserted row is $id\n";
		$dbh->commit();
	};

	if ($@) {
		warn "Database error inserting candidatecontact ($self->{contactaddress}, $self->{firstname}, $self->{lastname}): $DBI::errstr";
		$dbh->rollback();
	}
}

1;
