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

use File::Basename;
use File::Spec::Functions;
use Getopt::Std;
use Mac::Glue::Common ();

(my $VERSION) = ' $Revision: 1.2 $ ' =~ /\$Revision:\s+([^\s]+)/;
my $PROGNAME = basename($0);

my %opts;
usage('Options used incorrectly') unless getopts('hvadLUtuml', \%opts);
usage() if $opts{'h'} || (!@ARGV && !$opts{'L'});
version() if $opts{'v'};

my $switches = [ '-F', map { '-' . $_ } grep { $opts{$_} } qw(U t u m l) ];

my $glue = lc(shift @ARGV) || '';
(my $glue1 = $glue) =~ tr/ /_/;
(my $glue2 = $glue) =~ tr/_/ /;

my @dirs;
push @dirs, '' if ( (!$opts{'a'} && !$opts{'d'}) || $opts{'L'});
push @dirs, 'additions' if $opts{'a'} || $opts{'L'};
push @dirs, 'dialects'  if $opts{'d'} || $opts{'L'};

my %list;
OUTER: for my $dir (@dirs) {
	my $d = catfile($ENV{MACGLUEDIR}, $dir);
	opendir my $dh, $d or die $!;
	for my $f (readdir $dh) {
		if ($opts{'L'} && $f =~ /\.pod$/) {
			push @{$list{$dir}}, $f;
			next;
		}

		my $file = catfile($d, $f);
		next unless -f $file;		

		for (lc $f) {
			if (/^(?:\Q$glue\E|\Q$glue1\E|\Q$glue2\E)\.pod$/) {
				system('perldoc', @$switches, $file);
				last OUTER;
			}
		}
	}
}

if ($opts{'L'}) {
	for my $dir (sort keys %list) {
		printf "%s:\n", (ucfirst($dir) || "Glues");
		printf "  %s\n", join "\n  ", map { s/\.pod//; $_ } sort @{$list{$dir}};
		print "\n";
	}
}



sub usage {
	print "*** $_[0]\n" if $_[0];
	# Remember to doublecheck these match getopts()!
	print <<EOT;
Usage: $PROGNAME [OPTIONS] GLUE

This is a frontend to perldoc.  It searches for the docs of glues used
by Mac::Glue, and feeds them directly to perldoc.

	# same thing
	perldoc Mac::Glue::glues::Finder
	gluedoc Finder

	# open result in BBEdit
	gluedoc -t Finder | bbedit

Main options:
	-h	Help (this message)
	-v	Version
	-d	GLUE is a dialect (usually "AppleScript")
	-a	GLUE is a scripting addition (like "StandardAdditions")
	-L	List available glues

Options for perldoc (see man perldoc for more information):
	-t	text output
	-u	unformatted
	-m	module
	-l	file name only
	-U	run insecurely

EOT
	exit;
}

sub version {
	print <<EOT;
$PROGNAME $VERSION

Copyright (c) 1998-2003 Chris Nandor.  All rights reserved.  This program
is free software; you can redistribute it and/or modify it under the same
terms as Perl itself.

EOT
	exit;
}

__END__
!NO!SUBS!

close OUT or die "Can't close $file: $!";
chmod 0755, $file or die "Can't reset permissions for $file: $!\n";
exec("$Config{'eunicefix'} $file") if $Config{'eunicefix'} ne ':';
chdir $origdir;
