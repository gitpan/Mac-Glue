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
use DB_File;
use Data::Dumper;
use File::Spec::Functions;
use Mac::AETE::Format::Glue;
use Mac::Files;
use Mac::Glue;
use Symbol;

=pod

=head1 NAME

glueedit - Edit Mac::Glue glues

=head1 DESCRIPTION

Drop a glue file on here to create a file on the desktop to edit.
Save it back by dropping the text file back on the droplet again.
Careful: this droplet will evaluate the contents of the text
file, and then write to whatever file is named on the first line
of that file, and then save the contents of the file as a glue.
So be careful not to do something Bad.

=cut

my $dir = FindFolder(kOnSystemDisk, kDesktopFolderType);
my $gtype = $Mac::AETE::Format::Glue::TYPE || 'McPp';


for my $glue (@ARGV) {
    my $type = MacPerl::GetFileInfo($glue);
    if ($type eq $gtype) {
        get_glue($glue);
    } elsif ($type eq 'TEXT') {
        save_glue($glue);
    }
}

sub save_glue {
    my $file = shift;
    my $glue = {Mac::AETE::Format::Glue::_init(), DELETE => 1};

    my $fh = gensym;
    open $fh, "< $file" or die "Can't open $file: $!";

    chomp($glue->{OUTPUT} = <$fh>);
    my $dump;
    {   local $/;
        $dump = eval <$fh>;
    }
    close $fh;

    $glue->{N}  = $dump->{ENUM};
    $glue->{C}  = $dump->{CLASS};
    $glue->{E}  = $dump->{EVENT};
    $glue->{P}  = $dump->{COMPARISON};
    $glue->{ID} = $dump->{ID};

    Mac::AETE::Format::Glue::finish($glue, 1);  # 1 == no pod

    print <<EOT;
Created glue $glue->{OUTPUT}
   from file $file

EOT
}

    $dbm{ENUM}          = $self->{N};
    $dbm{CLASS}         = $self->{C};
    $dbm{EVENT}         = $self->{E};
    $dbm{COMPARISON}    = $self->{P};
    $dbm{ID}            = $self->{ID};

sub get_glue {
    my $glue = shift;
    tie my %db, 'MLDBM', $glue, O_RDONLY or die "Can't tie '$glue': $!";

    my $file = get_filename($db{ID});

    my $fh = gensym;
    open $fh, "> $file" or die "Can't open $file: $!";
    print $fh $glue, "\n";
    print $fh Dumper \%db;
    untie %db;

    print <<EOT;
Created file $file
    for glue $glue

EOT
}


sub get_filename {
    my $id = shift;
    my $c = '';
    $c++ while -e catfile($dir, "glueedit-$id$c.txt");
    return catfile($dir, "glueedit-$id$c.txt");
}

__END__
!NO!SUBS!

close OUT or die "Can't close $file: $!";
chmod 0755, $file or die "Can't reset permissions for $file: $!\n";
exec("$Config{'eunicefix'} $file") if $Config{'eunicefix'} ne ':';
chdir $origdir;
