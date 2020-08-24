package TTFS_File_Rename;

use File::Find;
use File::Basename;
use File::Spec::Functions qw(rel2abs);
use POSIX;
use File::Copy;
use strict;

my $path = dirname(__FILE__);
my @files;
my $base_path					= "./";  # top level
our $configfile					= "./config.cfg";
our $config_file_dir			= "./Rename";
my $start_run = time();


ReadConfig();

print "TTFS Renamer\n";

mkdir('export' ) unless(-d 'export' );
mkdir($config_file_dir) unless (-d $config_file_dir);

unless ( -e "$configfile" )
{
	print "configfile was not found. $configfile\n";
	return;
}


my @files = <$config_file_dir/*>;
foreach my $file (@files) 
{
  my $file_path = $file;
  #$file =~ s/$config_file_dir\///i;
  $file = substr($file, length( $config_file_dir ) + 1);
  my $temp = substr($file, 9);
  print $temp . "\n";
  my $dir = $path . "\\export\\";
  my $export_path = $dir . $temp;
  copy("$file_path", "$export_path" ) or die "Copy failed: $!";
}

my $end_run = time();
my $run_time = $end_run - $start_run;
print "Job took $run_time seconds\n";

sub ReadConfig
{
	my $fh;
	open ( $fh, $configfile ) or die "Config_File_Read: $!,";
	while ( <$fh> )
	{
		if ( $_ !~ m/^\#/ && $_ !~ m/^\s+$/ )		# If the line starts with a hash or is blank ignore it
		{
			if (/^\s*Directory\s*\=\s*(\S+)/i)							{ $config_file_dir = $1; }
		}
	}

	close $fh;
}