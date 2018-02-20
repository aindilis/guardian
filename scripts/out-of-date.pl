#!/usr/bin/perl -w

use BOSS::Config;
use PerlLib::SwissArmyKnife;

$specification = q(
	-f <file>		File to stat
);

my $config =
  BOSS::Config->new
  (Spec => $specification);
my $conf = $config->CLIConfig;
# $UNIVERSAL::systemdir = "/var/lib/myfrdcsa/codebases/minor/system";

die "Error: no -f existing\n" unless -f $conf->{'-f'};

my $t = time();
my @stat = stat($conf->{'-f'});
my $d = $t - $stat[9];
print "$d seconds\n";
