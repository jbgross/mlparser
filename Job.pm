#!/usr/bin/perl -w
use strict;

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

my $sure = 0;
my $termcount = 0;
my $matchedpercent = 0;
my $requiredpercent = 0.1;
my @matchedterms = ();

sub new ($) {
	my $class = shift;
	bless({}, $class); # Bestow objecthood
}

sub parse($) {
	my $self = shift;
	@matchedterms = ();
	$matchedpercent = 0;
	$sure = 0;
	my $sureterm = "";
	my $msg = shift;
	$termcount = scalar @searchterms;
	my $matchcount = 0;
	for my $term (@searchterms) {
		if ($msg =~ m/$term/i) {
			$matchcount++;
			if ($sureterms{$term}) {
				$sure = 1;
				$sureterm = $term;
				last;
			}
			push (@matchedterms, $term);
		}
	
	}
	$matchedpercent = $matchcount/$termcount;
	#if($matchcount > 4) { print "$matchcount matches $matchedpercent\n"; }
	#if($sure == 1) { print "sure $sureterm\n"; }
}

sub matchedTerms() {
	my $self = shift;
	return @matchedterms;
}

sub isJob {
	my $self = shift;
	if ($sure == 1 || $matchedpercent >= $requiredpercent) {
		return $matchedpercent;
	} else { 
		return 0;
	}
}

1;
