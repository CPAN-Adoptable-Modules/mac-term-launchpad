require 5.008;

die "OS unsupported! You need a Mac for this module!\n" 
	unless $^O =~ /darwin/;

package Mac::iTerm::LaunchPad;
use strict;
use warnings;

use File::Spec::Functions qw(catfile);

my $module    = __PACKAGE__;
my $github    = 'https://github.com/briandfoy/Mac-iTerm-LaunchPad';
my $main_file = catfile( 'lib', split /::/, "$module.pm" );

my %WriteMakefile = (
	'NAME'	        => $module,
	'ABSTRACT_FROM' => $main_file,
	'VERSION_FROM'  => $main_file,
	'LICENSE'	    => 'perl',
	'AUTHOR'        => 'brian d foy <bdfoy@cpan.org>',

	'CONFIGURE_REQUIRES' => {
		'ExtUtils::MakeMaker'   => '6.64',
		'File::Spec::Functions' => '0',
		'Mac::Glue'             => '0',
		},

	'BUILD_REQUIRES' => {
		},

	'TEST_REQUIRES' => {
		'Test::More' => '0.94',
		},

	'PREREQ_PM'     => {
		'Mac::Files'     => '0',
		'Mac::Glue'      => '1.28',
		'Mac::Processes' => '0',
		},

	'META_MERGE' => {
		'meta-spec' => { version => 2 },
		resources => {
			repository => {
				type => 'git',
				url  => "$github.git",
				web  => $github,
				},
			bugtraker => {
				web    => "$github/issues",
				},
			homepage => $github,
			},
		},
	
	clean  => { FILES    => q|Mac-iTerm-LaunchPad-*| },
	);

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# An auto installer should already have installed Mac::Glue

sub glueit {
require Mac::Glue;

my $iterm = eval { Mac::Glue->new( 'iTerm' ) };

if( $@ ) 
	{
	require Mac::Processes; Mac::Processes->import;
	
	my $iterm_path = LSFindApplicationForInfo( undef, undef, 'iTerm.app' );

	if( $iterm_path ) 
		{
		print <<"HERE";
To create the Mac::Glue bindings for iTerm you need to run:

	sudo gluemac $iterm_path

HERE

		print "Would you like to run this now? (y/N) ";

		chomp( my $confirm = <> );

		if( lc( $confirm ) eq 'y' ) 
			{
			system 'sudo', 'gluemac', $iterm_path;
			$iterm = eval { Mac::Glue->new( 'iTerm' ) };
			}
		}
	else
		{
		die "Could not find iTerm. Ensure you have it and try again\n";
		}
	}

unless( defined $iterm )
	{
	die "Cannot continue: Ensure that the iTerm glue for Mac::Glue is installed\n";
	}

}

sub arguments { \%WriteMakefile }

sub MY::postamble {
	<<'MAKE';
install :: new-iterm-install
	
new-iterm-install:
	$(ECHO) "Installing new-iterm symlink to module"
	/bin/ln -sfv $(INSTALLSITELIB)/Mac/iTerm/LaunchPad.pm $(INSTALLBIN)/new-iterm 
	$(CHMOD) 755 $(INSTALLSITELIB)/Mac/iTerm/LaunchPad.pm
MAKE
	}

do_it() unless caller;
sub do_it {
	glueit();
	my $MM ='ExtUtils::MakeMaker';
	my $MM_version =
		eval{ "$MM " . $WriteMakefile{'CONFIGURE_REQUIRES'}{'ExtUtils::MakeMaker'} }
			//
		"$MM 6.64";
	eval "use $MM_version" || die "Could not load $MM_version: $@";
	eval "use Test::Manifest 1.21" 
		if -e catfile( qw(t test_manifest) );
	WriteMakefile( %WriteMakefile );
	}


no warnings;
__PACKAGE__;
