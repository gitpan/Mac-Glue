#!perl
use strict;
use warnings;

use ExtUtils::MakeMaker;
use File::Basename;
use File::Spec::Functions;

my @scripts = map { catfile(curdir(), 'scripts', $_) }
	qw(gluedialect gluedoc glueedit gluemac gluescriptadds);
my %scripts = map { ("$_.PL" => $_) } @scripts;

WriteMakefile(
	'NAME'			=> 'Mac::Glue',
	'VERSION_FROM'		=> 'Glue.pm',
	'PL_FILES'		=> \%scripts,
	'EXE_FILES'		=> \@scripts,
	'MAN1PODS'		=> {},
	'PREREQ_PM'	=> {
		'Mac::Errors'                => 0.91,
		'Mac::Path::Util'            => 0.09,
    		'Mac::Apps::Launch'          => 1.81,
    		'Mac::AppleEvents'           => 1.27,
    		'Mac::AppleEvents::Simple'   => 1.08,
    		'Mac::Processes'             => 1.04,
		'MLDBM'                      => 0,
		'Storable'                   => 0,
    		'Test::More'                 => 0,
	},
	'clean'	=> {
		'FILES'	=> "Mac-Glue-* @scripts .makeglues"
	},
);

sub MY::postamble {
	return <<'MAKE_FRAG';
.makeglues: $(INST_SCRIPT)/gluedialect $(INST_SCRIPT)/gluescriptadds $(INST_SCRIPT)/gluemac
	@$(PERL) "-I$(INST_LIB)" make_glues "-I$(INST_LIB)" "$(INST_SCRIPT)"
	@$(TOUCH) .makeglues

all :: .makeglues

MAKE_FRAG
}


__END__
