#!/usr/bin/perl -w -I/home/jgross/dev/mlparser
use strict;
use Job;
use Message;


sub main {
	# make line separator the row of == signs
	$/="=========================================================================";
	
	my $msginfilecount = 0;
	my $msgcount = 0;
	my $filecount = 0;
	
	my %orgs;
	my %domains;

	# now loop through the each file in the ARGV list
	for my $file (@ARGV) {
		open (FILE, "<", $file) or die "Can't open $file for reading: $!";
		$filecount++;
		for my $msgText(<FILE>) {
			$msgcount++;
			$msginfilecount++;
	
			# ignore the 1st "message", since it's just the top row
			if ($msginfilecount == 1) {
				next;
			}
			my $msg = Message->new();
			$msg->parse($msgText);
			my ($month, $year) = ($msg->month(), $msg->year());
			my $org = $msg->organization();
			my $domain = $msg->domain();
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
			$orgs{$org} = $domain;


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
	for my $key(sort keys %orgs) {
		print "$key - $orgs{$key}\n";
	}
}


&main();
