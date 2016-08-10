#!/usr/bin/perl -w -I/home/jgross/dev/mlparser
use strict;
use Job;
use Message;


sub main {
	my $jobfile = shift(@ARGV);
	die "can't print to file $jobfile because it contains the word \"log\"\n" if ($jobfile =~ m/log/i);
	my $jobmsgfile = $jobfile.".messages";
	open (JOBOUTPUT, ">", $jobfile) or die "Can't open $jobfile for writing: $!";
	open (JOBMESSAGES, ">", $jobmsgfile) or die "Can't open $jobmsgfile for writing: $!";
	
	my $msginfilecount = 0;
	my $msgcount = 0;
	my $filecount = 0;
	my @jobs = ();
	
	my %orgs;
	my %domains;

	# now loop through the each file in the ARGV list
	for my $file (@ARGV) {
		open (FILE, "<", $file) or die "Can't open $file for reading: $!";
		$filecount++;
		#print STDERR "$filecount $file\n";

		# switch the line ending
		my $oldending = $/;
		my $newending="=========================================================================\nDate:";
		$/=$newending;

		for my $msgText(<FILE>) {
			$msgText="Date:$msgText";
			$msgcount++;
			$msginfilecount++;

			# ignore first separator
			if ($msginfilecount == 1) {
				next;
			}

			# temporarily switch back to old line ending
			$/=$oldending;
	
			# parse the message
			my $msg = Message->new();
			$msg->parse($msgText);

			# extract out the month & year (figure out when posted)
			my ($month, $year) = ($msg->month(), $msg->year());

			# extract organization
			my $org = $msg->organization();

			# extract domain (should be based principally on reply-to?
			my $domain = $msg->domain();

			# extract domain (should be based principally on reply-to?
			my $replyTo = $msg->replyTo();

			if($replyTo eq "0") { print "File: $file Message Number: $msginfilecount\n\n\n\n\n\n\n\n\n"; }

			#print "D: $domain \t O: $org \t R: $replyTo\n";

			if ($domain eq "0") {
				# we have a problem, no domain
				$domains{"error - no org in message # $msginfilecount"} = $file;
			} else {
				# overwrite an existing org if it's set to 0
				if (exists $domains{$domain}) {
					if($domains{$domain} eq "0") {
						$domains{$domain} = $org;
					}
				} else {
					$domains{$domain} = $org;
				}
			}

			# let's see if it's a job
			my $job = Job->new();
			$job->parse($msgText);
			if($job->isJob()) {
				# ignore these threads
				if ($msg->subject() =~ m/(Do you require|Faculty who are poor|how do you know if|Call For Part|capacity crisis in|Free workshop|Human Resource Machine|Need a strange kind|Is there some)/) {
					next;
				}

				push (@jobs, $msg);
				#print "job at ".$msg->organization()." ".$msg->replyTo()."\n";
				my @mt = $job->matchedTerms();
				my $mtc = scalar @mt;
				print JOBOUTPUT $msg->year()." ".$msg->month()." ".$msg->organization()." ".
					$msg->replyTo()." ".$job->isJob().
				#"@mt".
				" terms: $mtc".
				"\n";
				print JOBMESSAGES "@mt"."\n";
				print JOBMESSAGES "$msgText\n\n\n\n\n\n\n\n";
			}

			# add org to hash
			$orgs{$org} = $domain;

			$/=$newending;

		}
		close FILE;
		
		$msginfilecount = 0;
	}


	close JOBOUTPUT;
	close JOBMESSAGES;

	#&printOrgs(%domains);

	print scalar(keys %domains)." different domains\n";
	print scalar(keys %orgs)." different organizations\n";

	my $joblistsize = scalar @jobs;
	print "$joblistsize jobs in the list\n";

	$msgcount--;
	print "$msgcount total messages in $filecount files\n";
}

sub printOrgs (%) {
	my %orgs = @_;
	print "Printing Orgs domain - organization\n";
	for my $key(sort keys %orgs) {
		print "$key - $orgs{$key}\n";
	}
}

&main();
