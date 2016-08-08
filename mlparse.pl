#!/usr/bin/perl -w -I/home/jgross/dev/mlparser
use strict;
use Job;
use Message;


sub main {
	# make line separator the row of = signs
	
	my $msginfilecount = 0;
	my $msgcount = 0;
	my $filecount = 0;
	
	my %orgs;
	my %domains;

	# now loop through the each file in the ARGV list
	for my $file (@ARGV) {
		open (FILE, "<", $file) or die "Can't open $file for reading: $!";
		$filecount++;

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
			$job->parse($msg);

			# add org to hash
			$orgs{$org} = $domain;

			$/=$newending;

		}
		close FILE;
		$msginfilecount = 0;
	}

	&printOrgs(%domains);

	print scalar(keys %orgs)." different organizations\n";

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
