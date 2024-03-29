#!perl
use Config;
use File::Basename qw(basename dirname);
use Cwd;

$origdir = cwd;
chdir dirname($0);
$file = basename($0, '.PL');
$file .= '.com' if $^O eq 'VMS';

open OUT,">$file" or die "Can't create $file: $!";

print "Extracting $file (with variable substitutions)\n";

print OUT <<"!GROK!THIS!";
$Config{startperl}
!GROK!THIS!

# In the following, perl variables are not expanded during extraction.

print OUT <<'!NO!SUBS!';
use strict;
use warnings;
no warnings 'uninitialized';

BEGIN {
	($Mac::Glue::Common::PROGVERSION) =
		' $Revision: 1.3 $ ' =~ /\$Revision:\s+([^\s]+)/;
	$Mac::Glue::Common::PROGDESC = <<'EOT';
Creates application glues for use with Mac::Glue.  Pass in scriptable
applications on the command line.

Read the documentation for created glues with the gluedoc program.

	-c	Check installed glue versions against app versions
	-r	Re-make all installed glues (with -c, only those glues
		where the app versions don't match)
EOT
	$Mac::Glue::Common::PROGOPTS = 'cr';
}

use File::Spec::Functions;
use Mac::Glue::Common;
use Mac::Processes;

my $opts = opts();
if ($opts->{c} || $opts->{r}) {
	gluecheck();
} else {
	glue($opts, \@ARGV);
}

sub gluecheck {
	require Mac::Glue;

	my @paths;
	opendir my $dh, $MACGLUEDIR or die $!;
	for my $name (sort readdir $dh) {
		next if $name =~ /\.pod$/;
		next unless -f catfile($MACGLUEDIR, $name);
		next if $name eq 'FontSyncScripting'; # something's wrong ... ?

		my $glue = new Mac::Glue $name;
		if ($opts->{c}) {
			eval {
				$glue->{TIMEOUT} = 10;
				my($g1, $g2) = ($glue->version, $glue->{VERSION});

				if ($g1 ne $g2 || $name eq 'Finder') {
					my $path = _get_path($glue);
					die "Can't find $name\n" if !$path;

					if ($opts->{r}) {
						push @paths, $path;
					} else {
						my $command = "$0 $path";
						$command = "sudo $ENV{_} $command" if $ENV{SUDO_COMMAND};
						print "$g1 ne $g2:\n   $command\n";
					}
				}
				1;
			} or warn "Error for $name: $@";
		} elsif ($opts->{r}) {
			push @paths, _get_path($glue);
		}
	}
	glue($opts, \@paths) if @paths && $opts->{r};
}

sub _get_path {
	my($glue) = @_;
	my $path;
	if ($glue->{ID} && $glue->{ID} ne '????') {
		if (length($glue->{ID}) == 4) {
			$path = LSFindApplicationForInfo($glue->{ID});
		}
		$path ||= LSFindApplicationForInfo('', $glue->{ID});
	}
	$path ||= LSFindApplicationForInfo('', '', $glue->{APPNAME});
	$path ||= LSFindApplicationForInfo('', '', $glue->{APPNAME} . '.app');
	return $path;
}

__END__
!NO!SUBS!

close OUT or die "Can't close $file: $!";
chmod 0755, $file or die "Can't reset permissions for $file: $!\n";
exec("$Config{'eunicefix'} $file") if $Config{'eunicefix'} ne ':';
chdir $origdir;
