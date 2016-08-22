#!/usr/bin/perl -w
use strict;
use Message;

package Job;

my $requiredpercent = 0.1;

my $badsubjects = "(do you require|faculty who are poor|how do you know if|call for part|call for papers|capacity crisis in|free workshop|human resource machine|need a strange kind|is there some|denice denton|share what you|analytic skills|respect 2016|philosophy of assigning|alternatives to scratch|cfp|share your work|share what you|flipped classroom book|eduplop|icer|toce editor|deadline for acm|nsf-funded|eduhpc|travel grant|cra invites|experiences hiring into|hosting a course on github|questions regarding abet|women in cybersecurity conference|forced distribution|CSAB|fizzbuzz|iticse|issue|projects|GHC Scholarship)";

my @searchterms = (
'assistant or associate',
'apply',
'applications?',
'accepting',
'application process',
'appointment',
'evaluation of applications',
'employment',
'invites',
'opportunit(y|ies)',
'positions?',
'position is filled',
'positions are filled',
'hiring',
'opening',

'candidates',
'employer',
'diversity',
'title ix',

'full[- ]?time',
'tenure[- ]+track',
'non[- ]+tenure[- ]+track',
'security of employment',
'rank',
'(assistant|associate|full) professor',
'teaching (faculty|professor|stream)',
'lecturer',
'instructor',
'professor of (the )?practice',
'visiting',

'earned doctorate',
'ph\.?d\.? in computer science',
'relevant experience',

'curriculum vita',
'c\.?v',
'cover letter',
'demonstration of teaching',
'statement of teaching',
'teaching statement'
);

my %sureterms = (
'encouraged to apply' => 1,
'prohibits discrimination' => 1,
'equal opportunity' => 1,
'affirmative action' => 1,
'background investigation' => 1
);

# add the sureterms to the searchterms
push (@searchterms, (keys %sureterms));

# count the searchterms
my $termcount = scalar @searchterms;

sub new ($) {
	my $class = shift;
	my $self = {};
	$self->{sure} = 0;
	$self->{sureterm} = "";
	$self->{matchcount} = 0;
	$self->{matchpercent} = 0;
	$self->{wordcount} = 0;
	$self->{ratio} = 0;
	$self->{badsubject} = 0;
	$self->{message} = "";
	# empty array reference
	$self->{matchedterms} = [];
	bless($self, $class); # Bestow objecthood
}

sub parse($) {
	my $self = shift;
	$self->{message} = shift;

	my $body = $self->{message}->subject()." ".$self->{message}->messageBody();
	$self->{wordcount} = scalar (split(" ", $body));

	if ($self->{message}->subject() =~ m/$badsubjects/i) {
		$self->{badsubject} = 1;
		return;
	}


	for my $term (@searchterms) {
		if ($body =~ m/$term/i) {
			$self->{matchcount}++;
			if ($sureterms{$term}) {
				$self->{sure} = 1;
				$self->{sureterm} = $term;
				last;
			}
			push ($self->{matchedterms}, $term);
		}
	
	}
	$self->{matchpercent} = $self->{matchcount}/$termcount;
	$self->{ratio} = $self->{matchcount}/$self->{wordcount};
	#if($self->{matchcount} > 4) { print "$self->{matchcount} matches $self->{matchpercent}\n"; }
	#if($self->{sure} == 1) { print "sure $self->{sure}term\n"; }
}

sub matchedTerms() {
	my $self = shift;
	return $self->{matchedterms};
}

sub isJob {
	my $self = shift;
	if ($self->{sure} == 1 || $self->{matchpercent} >= $requiredpercent) {
		return $self->{matchpercent};
	} else { 
		return 0;
	}
}

sub addToDatabase {
	my $self = shift;
	my $dbh = shift;
	eval {
		my $insertjm = "insert into jobmessage (messageid, sure, matchcount, matchpercent, wordcount, ratio, badsubject) ".
				"values (?, ?, ?, ?, ?, ?, ?)";
		my $sth = $dbh->prepare($insertjm);
		$sth->bind_param(1, $self->{message}->messageId(), $DBI::SQL_INTEGER);
		$sth->bind_param(2, $self->{sure}, $DBI::SQL_INTEGER);
		$sth->bind_param(3, $self->{matchcount}, $DBI::SQL_INTEGER);
		$sth->bind_param(4, $self->{matchpercent}, $DBI::SQL_DOUBLE);
		$sth->bind_param(5, $self->{wordcount}, $DBI::SQL_INTEGER);
		$sth->bind_param(6, $self->{ratio}, $DBI::SQL_DOUBLE);
		$sth->bind_param(7, $self->{badsubject}, $DBI::SQL_INTEGER);
		$sth->execute();
		$dbh->commit();
	};

	if(@_) {
		warn "Error inserting jobmessage messageid: $self->{message}->messageId()\n";
		$dbh->rollback();
	}
}


1;
