#!/usr/bin/perl -w -I/home/jgross/dev/mlparser
use strict;
use Job;
use Message;
use DBI;

my $notmatches =
"(do you require|faculty who are poor|how do you know if|call for part|call for papers|capacity crisis in|free workshop|human resource machine|need a strange kind|is there some|denice denton|share what you|analytic skills|respect 2016|philosophy of assigning|alternatives to scratch|cfp|share your work|share what you|flipped classroom book|eduplop|icer|toce editor|deadline for acm|nsf-funded|eduhpc|travel grant|cra invites|experiences hiring into|hosting a course on github|questions regarding abet|women in cybersecurity conference|forced distribution|CSAB)";

my $dbh = 0;

sub main {

	my $dbname = shift(@ARGV);
	die "Can't open a database with the word log in it." if ($dbname =~ m/log/i);

	$dbh = DBI->connect("dbi:SQLite:dbname=$dbname") || die "Can't open database: $DBI::errstr";
	$dbh->{AutoCommit} = 0;

	Message::addDatabase($dbh);
	
	my $msginfilecount = 0;
	my $msgcount = 0;
	my $filecount = 0;
	my $jobcount = 0;
	
	my %orgs;
	my %domains;

	# now loop through the each file in the ARGV list
	for my $file (@ARGV) {
		open (FILE, "<", $file) or die "Can't open $file for reading: $!";

		warn "File $file starting message count: $msgcount\n";
		$filecount++;

		# switch the line ending
		my $oldending = $/;
		my $newending="=========================================================================\nDate:";

		$/=$newending;


		for my $msgText(<FILE>) {
			$msgText="Date:".$msgText;
			$msgcount++;
			$msginfilecount++;

			# strip off separator (which will be at the end!)
			$msgText =~ s/$newending//g;

			# ignore first"\n"; separator
			if ($msginfilecount == 1) {
				next;
			}

			# temporarily switch back to old line ending
			$/=$oldending;

			# parse the message
			my $msg = Message->new();
			$msg->parse($msgText, $file);

			# extract organization and domain
			my $org = $msg->organization();
			my $domain = $msg->domain();

			# overwrite an existing org if it's set to empty string
			if (exists $domains{$domain}) {
				if($domains{$domain} eq "") {
					$domains{$domain} = $org;
				}
			} else {
				$domains{$domain} = $org;
			}

			# add org to hash
			$orgs{$org} = $domain;

			# let's see if it's a job
			my $job = Job->new();
			$job->parse($msg);

			if($job->isJob()) {
				if ($msg->subject() !~ m/$notmatches/i) {
					$msg->setJob(1);
					$jobcount++;
				}
			}

			# add to database
			$msg->addToDatabase($dbh);
			$job->addToDatabase($dbh);


			# split on ending again
			$/=$newending;

		} # done parsing each message

		close FILE;

		# need to remove first false message for each file
		$msgcount--;
		$msginfilecount--;

		warn "File $file ending message count: $msgcount which should be before plus $msginfilecount\n";
		
		# reset
		$msginfilecount = 0;

	} # done parsing each file


	$dbh->disconnect();

	#&printOrgs(%domains);

	print scalar(keys %domains)." different domains\n";
	print scalar(keys %orgs)." different organizations\n";

	print "$jobcount job messages in the list\n";

	print "$msgcount total messages in $filecount files\n";
}

sub addToDatabase {
	my ($message, $job) = @_;
}

sub printOrgs (%) {
	my %orgs = @_;
	print "Printing Orgs domain - organization\n";
	for my $key(sort keys %orgs) {
		print "$key - $orgs{$key}\n";
	}
}

&main();
