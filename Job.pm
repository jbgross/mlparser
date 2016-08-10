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

'encouraged to apply',
'prohibits discrimination',
'candidates',
'equal opportunity',
'affirmative action',
'employer',
'diversity',
'background investigation',
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

my $termcount = 0;
my $job = 0;
my $matchpercent = 0.2;
my @matchedterms = ();

sub new ($) {
	my $class = shift;
	bless({}, $class); # Bestow objecthood
}

sub parse($) {
	my $self = shift;
	@matchedterms = ();
	$job = 0;
	my $msg = shift;
	$termcount = scalar @searchterms;
	my $matchcount = 0;
	for my $term (@searchterms) {
		if ($msg =~ m/$term/i) {
			$matchcount++;
			push (@matchedterms, $term);
		}
	}
	$job = $matchcount/$termcount;
	#if($matchcount > 4) { print "$matchcount matches $job\n"; }
}

sub matchedTerms() {
	my $self = shift;
	return @matchedterms;
}

sub isJob {
	my $self = shift;
	#if ($job >= $matchpercent) {
	if ($job > 0.1 && $job < $matchpercent) {
		return $job;
	} else { 
		return 0;
	}
}

1;
