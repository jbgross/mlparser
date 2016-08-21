#!/usr/bin/perl -w
use strict;
use Message;

package Job;

my @searchterms = (
'apply',
'applications?',
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

my $requiredpercent = 0.1;
my $termcount = scalar @searchterms;

sub new ($) {
	my $class = shift;
	my $self = {};
	$self->{sure} = 0;
	$self->{sureterm} = "";
	$self->{matchcount} = 0;
	$self->{matchedpercent} = 0;
	# empty array reference
	$self->{matchedterms} = [];
	bless($self, $class); # Bestow objecthood
}

sub parse($) {
	my $self = shift;
	my $msg = shift;

	my $body = $msg->subject()." ".$msg->messageBody();

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
	$self->{matchedpercent} = $self->{matchcount}/$termcount;
	#if($self->{matchcount} > 4) { print "$self->{matchcount} matches $self->{matchedpercent}\n"; }
	#if($self->{sure} == 1) { print "sure $self->{sure}term\n"; }
}

sub matchedTerms() {
	my $self = shift;
	return $self->{matchedterms};
}

sub isJob {
	my $self = shift;
	if ($self->{sure} == 1 || $self->{matchedpercent} >= $requiredpercent) {
		return $self->{matchedpercent};
	} else { 
		return 0;
	}
}

1;
