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
$Config{startperl} -w
!GROK!THIS!

# In the following, perl variables are not expanded during extraction.

print OUT <<'!NO!SUBS!';
use strict;

BEGIN {
	($Mac::Glue::Common::PROGVERSION) =
		' $Revision: 1.1 $ ' =~ /\$Revision:\s+([^\s]+)/;
	$Mac::Glue::Common::PROGDESC = <<'EOT';
Creates application glues for use with Mac::Glue.  Pass in scriptable
applications on the command line.

Read the documentation for created glues with the gluedoc program.
EOT
}

use Mac::Glue::Common;

my $opts = opts();
glue($opts, \@ARGV);

__END__
!NO!SUBS!

close OUT or die "Can't close $file: $!";
chmod 0755, $file or die "Can't reset permissions for $file: $!\n";
exec("$Config{'eunicefix'} $file") if $Config{'eunicefix'} ne ':';
chdir $origdir;
