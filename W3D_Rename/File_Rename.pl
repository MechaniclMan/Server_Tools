package W3D_File_Rename;

use File::Find;
use File::Basename;
use File::Spec::Functions qw(rel2abs);
use POSIX;
use File::Copy;
use strict;

my $path = dirname(__FILE__);
my @files;
my @w3dfiles;
my $base_path					= "./";  # top level
our $configfile					= "./config.cfg";
our $config_file_dir			= "./Rename";
our $config_copy_file			= "";
our $config_change				= 0;
our $config_add_name			= "rxd";
our $config_w3d_folder			= 0;

my $start_run = time();


ReadConfig();

print "File Renamer\n";

mkdir('export' ) unless(-d 'export' );
mkdir($config_file_dir) unless (-d $config_file_dir);

unless ( -e "$configfile" )
{
	print "configfile was not found. $configfile\n";
	return;
}

my $file_path = "";
my @files = <$config_file_dir/*>;
foreach my $file (@files) 
{
	
  if ( $file =~ /^(.+).w3d$/ )
  {
	  my $w3dfile = $1;
	  print("w3d match: $w3dfile\n");
	  $w3dfile = substr($w3dfile, length( $config_file_dir ) + 1);
	  print("new w3d: $w3dfile\n");
	  push @w3dfiles, $w3dfile;
	  next if ( $config_w3d_folder );
  }
 	
  if ( $config_copy_file )
  {
	print("Copying from one file $config_copy_file\n");
	$file_path = $path . "\\" . $config_copy_file;
  }
  else
  {
	print("Renaming Files\n");
	$file_path = $file;
  }
  
  $file = substr($file, length( $config_file_dir ) + 1);
  my $temp = substr($file, 9);	
	
  #my $dir = $path . "\\export\\";
  my $dir = $path . "\\export\\";
  my $export_path = $dir . $config_add_name;  
  my $change_file = $file;
  
  if ( $config_add_name )
  {
	  #Remove file type
	  my $temp = substr($file, -4);
	  print("Remove subst 3: $temp\n");
	  $change_file =~ s/$temp//;
	  #if ( $file =~ m/^(.+?) is (\d+\.\d+)\sr(\d+)?/i )
	  #my $temp2 = substr($file, 0, -3);
      print("CF: $change_file\n");
	  
	  $change_file = $change_file . "_" . $config_add_name;
	  print("ChangeFile: $change_file\n");
	  $export_path = $dir . $change_file;
  }
  else
  {
	  $export_path = $dir . $file;
  }
  
  
  print "File_Path: $file_path\n";
  print "Change File: $change_file\n";
  print "Export: $export_path\n";
  print "File: $file\n";  
  
  
  copy("$file_path", "$export_path" ) or die "Copy failed: $!"; 

}

if ( $config_w3d_folder )
{
print "W3DFolder\n"; 
foreach my $w3d (@w3dfiles) 
{
	
	my $w3dfile = $w3d . ".w3d"; 
	my $dir = $path . "\\export\\$w3d";
	my $file_path = $path . "\\" . $config_file_dir . "\\" . $w3dfile;
	my $export_path = $dir . "\\" . $w3dfile;
	mkdir( $dir ) unless(-d $dir );
	
	print "W3D: $w3d\n";
	print "Dir: $dir\n";
	print "File_Path: $file_path\n";
	print "Export: $export_path\n";
	print "File: $w3dfile\n";  	
	
	
	copy("$file_path", "$export_path" ) or die "Copy failed: $!";
}  
}

my $end_run = time();
my $run_time = $end_run - $start_run;
print "Job took $run_time seconds\n";
sleep 10;
exit;

sub ReadConfig
{
	my $fh;
	open ( $fh, $configfile ) or die "Config_File_Read: $!,";
	while ( <$fh> )
	{
		if ( $_ !~ m/^\#/ && $_ !~ m/^\s+$/ )		# If the line starts with a hash or is blank ignore it
		{
			if (/^\s*Directory\s*\=\s*(\S+)/i)							{ $config_file_dir = $1; }
			if (/^\s*File\s*\=\s*(\S+)/i)								{ $config_copy_file = $1; }
			if (/^\s*Create_W3D_Folder\s*\=\s*(\S+)/i)					{ $config_w3d_folder = $1; }
			if (/^\s*Change_Name\s*\=\s*(\S+)/i)						{ $config_change = $1; }
			if (/^\s*Add_Name\s*\=\s*(\S+)/i)							{ $config_add_name = $1; }
		}
	}

	close $fh;
}