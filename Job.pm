#!/usr/bin/perl -w
use strict;
use Message;

package Job;

my $requiredpercent = 0.1;

my $badsubjects = "(do you require|faculty who are poor|how do you know if|call for part|call for papers|capacity crisis in|free workshop|human resource machine|need a strange kind|is there some|denice denton|share what you|analytic skills|respect 2016|philosophy of assigning|alternatives to scratch|cfp|share your work|share what you|flipped classroom book|eduplop|icer|toce editor|deadline for acm|nsf-funded|eduhpc|travel grant|cra invites|experiences hiring into|hosting a course on github|questions regarding abet|women in cybersecurity conference|forced distribution|CSAB|fizzbuzz|iticse|issue|projects|GHC Scholarship|search management)";

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
	$self->{badsubject} = 0;

	$self->{tenured} = 0;
	$self->{tenuretrack} = 0;
	$self->{nontenuretrack} = 0;
	$self->{instructor} = 0;
	$self->{lecturer} = 0;
	$self->{assistantprofessor} = 0;
	$self->{associateprofessor} = 0;
	$self->{teachingprofessor} = 0;
	$self->{professorofpractice} = 0;
	$self->{phd} = 0;
	$self->{earneddoctorate} = 0;
	$self->{masters} = 0;
	$self->{securityofemployment} = 0;
	$self->{temporaryfixed} = 0;
	$self->{visiting} = 0;
	$self->{multiple} = 0;
	$self->{fulltime} = 0;
	$self->{parttime} = 0;
	$self->{rankopen} = 0;
	$self->{adjunct} = 0;

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

	$self->parseKeywords();

	#if($self->{matchcount} > 4) { print "$self->{matchcount} matches $self->{matchpercent}\n"; }
	#if($self->{sure} == 1) { print "sure $self->{sure}term\n"; }
}

sub parseKeywords {
	my $self = shift;
	my $body = $self->{message}->subject()." ".$self->{message}->messageBody();
	$self->{tenured} = 1 if ($body =~ m/tenured/i);
	# actually have to purge this so that we can match tenure-track
	$self->{nontenuretrack} = 1 if ($body =~ s/non[ -]tenure[- ]track//ig);
	$self->{tenuretrack} = 1 if ($body =~ m/tenure[ -]track/i);
	$self->{instructor} = 1 if ($body =~ m/tenured/i);
	$self->{lecturer} = 1 if ($body =~ m/lecturer/i);
	$self->{assistantprofessor} = 1 if ($body =~ m/assistant professor/i);
	$self->{associateprofessor} = 1 if ($body =~ m/associate professor/i);
	$self->{teachingprofessor} = 1 if ($body =~ m/teaching (associate|assistant|full)? professor/i);
	$self->{professorofpractice} = 1 if ($body =~ m/professor of (the )?practice/i);
	$self->{phd} = 1 if ($body =~ m/phd/i);
	$self->{earneddoctorate} = 1 if ($body =~ m/earned (doctorate|doctoral degree)/i);
	$self->{masters} = 1 if ($body =~ m/(master\'?s|MS)/);
	$self->{securityofemployment} = 1 if ($body =~ m/(security of employment|employment security)/i);
	$self->{temporaryfixed} = 1 if ($body =~ m/(temporary|fixed[ -]term)/i);
	$self->{visiting} = 1 if ($body =~ m/visiting/i);
	$self->{multiple} = 1 if ($body =~ m/multiple/i);
	$self->{fulltime} = 1 if ($body =~ m/full[ -]?time/i);
	$self->{parttime} = 1 if ($body =~ m/part[ -]?time/i);
	$self->{rankopen} = 1 if ($body =~ m/(rank open|open rank)/i);
	$self->{adjunct} = 1 if ($body =~ m/adjunct/i);
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
		my $insertjm = "insert into jobmessage (".
				"messageid, sure, matchcount, matchpercent, ". #1-4
				"wordcount, ratio, badsubject, tenured, ". #5-8
				"tenuretrack, nontenuretrack, instructor, lecturer, ". #9-12
				"assistantprofessor, associateprofessor, teachingprofessor, professorofpractice, ".#13-16
				"phd, earneddoctorate, masters, securityofemployment, ". #17-20
				"temporaryfixed, visiting, multiple, fulltime, ". #21-24
				"parttime, rankopen, adjunct". #25-27
				") values (".
				"?, ?, ?, ?, ?, ?, ?, ?, ".
				"?, ?, ?, ?, ?, ?, ?, ?, ".
				"?, ?, ?, ?, ?, ?, ?, ?, ".
				"?, ?, ?".
				")";

		my $sth = $dbh->prepare($insertjm);

		$sth->bind_param(1, $self->{message}->messageId(), $DBI::SQL_INTEGER);
		$sth->bind_param(2, $self->{sure}, $DBI::SQL_INTEGER);
		$sth->bind_param(3, $self->{matchcount}, $DBI::SQL_INTEGER);
		$sth->bind_param(4, $self->{matchpercent}, $DBI::SQL_DOUBLE);
		$sth->bind_param(5, $self->{wordcount}, $DBI::SQL_INTEGER);
		$sth->bind_param(6, $self->{ratio}, $DBI::SQL_DOUBLE);
		$sth->bind_param(7, $self->{badsubject}, $DBI::SQL_INTEGER);
		$sth->bind_param(8, $self->{tenured}, $DBI::SQL_INTEGER);
		$sth->bind_param(9, $self->{tenuretrack}, $DBI::SQL_INTEGER);
		$sth->bind_param(10, $self->{nontenuretrack}, $DBI::SQL_INTEGER);
		$sth->bind_param(11, $self->{instructor}, $DBI::SQL_INTEGER);
		$sth->bind_param(12, $self->{lecturer}, $DBI::SQL_INTEGER);
		$sth->bind_param(13, $self->{assistantprofessor}, $DBI::SQL_INTEGER);
		$sth->bind_param(14, $self->{associateprofessor}, $DBI::SQL_INTEGER);
		$sth->bind_param(15, $self->{teachingprofessor}, $DBI::SQL_INTEGER);
		$sth->bind_param(16, $self->{professorofpractice}, $DBI::SQL_INTEGER);
		$sth->bind_param(17, $self->{phd}, $DBI::SQL_INTEGER);
		$sth->bind_param(18, $self->{earneddoctorate}, $DBI::SQL_INTEGER);
		$sth->bind_param(19, $self->{masters}, $DBI::SQL_INTEGER);
		$sth->bind_param(20, $self->{securityofemployment}, $DBI::SQL_INTEGER);
		$sth->bind_param(21, $self->{temporaryfixed}, $DBI::SQL_INTEGER);
		$sth->bind_param(22, $self->{visiting}, $DBI::SQL_INTEGER);
		$sth->bind_param(23, $self->{multiple}, $DBI::SQL_INTEGER);
		$sth->bind_param(24, $self->{fulltime}, $DBI::SQL_INTEGER);
		$sth->bind_param(25, $self->{parttime}, $DBI::SQL_INTEGER);
		$sth->bind_param(26, $self->{rankopen}, $DBI::SQL_INTEGER);
		$sth->bind_param(27, $self->{adjunct}, $DBI::SQL_INTEGER);

		$sth->execute();
		$dbh->commit();
	};

	if(@_) {
		warn "Error inserting jobmessage messageid: $self->{message}->messageId()\n";
		$dbh->rollback();
	}
}


1;
