#!/usr/bin/perl -w
use strict;
use File::Copy;
use File::Path qw( make_path rmtree ); 
use Cwd qw(getcwd);

my @maps = ();
my @themaps = ();
my @Exclude_Rotation = ();

my $config_new_ttfs						= 0;
my $config_author						= "MapInstaller";
my $config_packages						= "";
my $config_version						= 2.2;
my $config_map_version					= 1.0;
my $config_extra_packages 				= 0;
my $config_map_prefix					= 'C&C';
my $config_map_directory 				= 'Maps';
my $config_install_file 				= 'install.txt';
my $config_ttcfg_file 					= 'tt.cfg';
my $config_rxd_package					= 'RxD4.6';
my $config_repository					= "";
my $config_export_directory 			= $config_map_directory;
my $config_remove_periods 				= 0;

ReadConfig();

print "---------------------------------------------\n";
print "Scripts 4.0 Map Installer v$config_version\n";
print "---------------------------------------------\n";

my $path = getcwd;
my $directory = $config_map_directory;
my $install = $config_export_directory . '/' . $config_install_file;
my $ttcfg = $config_export_directory . '/' . $config_ttcfg_file;
my $ttcfg_backup = $config_export_directory . '/tt_backup.txt';
my $mydef;
my $author = $config_author;
my $version = $config_map_version;
my $packages = $config_packages;
my $packageslength = length($packages);

mkdir( $config_map_directory ) unless(-d $config_map_directory );
unlink $install if ( -e $install );
#if ( -e $ttcfg_backup ) {
#	unlink $ttcfg_backup if ( -e $ttcfg_backup );
#	copy("$ttcfg", "$ttcfg_backup" )
#}
unlink $ttcfg if ( -e $ttcfg );
rmtree('Renegade') if ( -d 'Renegade' && $config_new_ttfs);

#Get Maps from maps folder
opendir ( my $mapsfh, $directory) or die $directory;
while (my $file = readdir($mapsfh)) 
{
	#next if ($file =~ m/^\./);
	next if ($file !~ m/^.+\.mix$/); #Must be a .mix file
	next if ($file =~ /\s/); #Skip files with spaces
	if ( $config_remove_periods )
	{
		next if ($file =~ m/^.+\..+\.mix$/);
	}
	
	unless ( $config_extra_packages )
	{
		push (@maps, $file) if ( $file =~ m/^$config_map_prefix/i );	
	}
	else {
		push (@maps, $file);
	}
}
closedir($mapsfh);

if (!@maps)
{
	print "No Packages Found. There is nothing to process.\n";
	print "No Maps with \"$config_map_prefix\" Found.\n" if ( !$config_extra_packages );
	sleep(5);
	exit (0);
}


#convert maps and create install file
foreach my $map ( @maps )
{
	print "Converting $map\n";
	system("PackageEditor.exe convert \"$directory\\$map\" $version $author >> \"$config_export_directory\\$config_install_file\"");
    if ($? != 0) 
	{
		print "$map Failed to Convert!\n";
    }
}
print "\n";

#install packages
open(my $install_fh, "<", $install) or die("Could not open Install.txt.");
foreach my $line (<$install_fh>) 
{
	$line =~ s/[\$#@~!&*()\[\];.,:?^ `\\\/]+//g;
	if ( $line =~ m/packageeditorinstall(.+)'/ )
	{
		system("PackageEditor.exe install $1");
	}
}
close ( $install_fh );
print "\n";

#display packages
system("PackageEditor.exe list");

#make new array with maps only
foreach my $line ( @maps )
{
	if ( $line =~ m/^c\&c_.+/i )
	{
		push (@themaps, $line);
	}
}

print "\n";
print "Generating $config_ttcfg_file\n";

#generate tt.cfg
open(my $ttcfg_fh, ">", $ttcfg) or die("Could not open tt.cfg $ttcfg");
print $ttcfg_fh "gameDefinitions:\n";
print $ttcfg_fh "{\n";
foreach my $line ( @themaps )
{
	my $rxd = 0;
	$mydef = $line;
	$rxd = 1 if ( $mydef =~ /RxD/i );
	$mydef =~ s/\.mix//i;	$mydef =~ s/c\&c_//i; $mydef =~ s/\.//i; $mydef =~ s/ //i;
	$line =~ s/\.mix//i;
	print $ttcfg_fh "	$mydef:\n";
	print $ttcfg_fh "	{\n";
	print $ttcfg_fh "		mapName = \"$line\";\n";
	if ( $packageslength > 2 )
	{
		if ( $rxd )
		{
			print $ttcfg_fh "		packages = [\"$line\",\"$config_rxd_package\",$packages];\n";
		}
		else
		{
			print $ttcfg_fh "		packages = [\"$line\",$packages];\n";
		}
	}
	else
	{
		if ( $rxd )
		{
			print $ttcfg_fh "		packages = [\"$line\",\"$config_rxd_package\"];\n";
		}
		else
		{
			print $ttcfg_fh "		packages = [\"$line\"];\n";
		}
	}
	print $ttcfg_fh "	};\n";
}
print $ttcfg_fh "};\n";
print $ttcfg_fh "\n";
print $ttcfg_fh "rotation:\n";
print $ttcfg_fh "[\n";
foreach my $line ( @themaps )
{
	$mydef = $line;
	$mydef =~ s/\.mix//i;	
	$mydef =~ s/c\&c_//i; 
	$mydef =~ s/^$config_map_prefix//i;
	$mydef =~ s/\.//i; $mydef =~ s/ //i;
	
	my $break = 0;
	foreach my $x ( @Exclude_Rotation ) 
	{
		chomp $x;
		$break = 1 if ( $line eq $x );
	}
	next if ( $break == 1 );
	
	
	if ( $themaps[$#themaps] eq $line )
	{
		print $ttcfg_fh "	\"$mydef\"\n";
	}
	else
	{
		print $ttcfg_fh "	\"$mydef\",\n";
	}
}
print $ttcfg_fh "];\n";
print $ttcfg_fh "\n";
print $ttcfg_fh "downloader:\n";
print $ttcfg_fh "{\n";
print $ttcfg_fh "	repositoryUrl = \"$config_repository\";\n";
print $ttcfg_fh "};\n";
close ( $ttcfg_fh );
print "Done!\n";
sleep(5);
exit (1);



sub ReadConfig
{
	my $configfile = "MapInstaller.cfg";
	open ( my $fh, $configfile ) or die "MapInstaller.cfg not found!";
	while ( <$fh> )
	{
		if ( $_ !~ m/^\#/ && $_ !~ m/^\s+$/ )
		{
			if 	  (/^\s*Map_Prefix\s*=\s*(.+)/i)							{ $config_map_prefix = $1; }
			elsif (/^\s*Map_Directory\s*=\s*(.+)/i)							{ $config_map_directory = $1; }
			elsif (/^\s*Export_Directory\s*=\s*(.+)/i)						{ $config_export_directory = $1; }
			elsif (/^\s*TTConfig\s*=\s*(.+)/i)								{ $config_ttcfg_file = $1; }
			elsif (/^\s*InstallLog\s*=\s*(.+)/i)							{ $config_install_file = $1; }
			
			elsif (/^\s*New_TTFS\s*=\s*(.+)/i)								{ $config_new_ttfs = $1; }
			elsif (/^\s*Remove_Periods\s*=\s*(.+)/i)						{ $config_remove_periods = $1; }
			elsif (/^\s*MapAuthor\s*=\s*(.+)/i)								{ $config_author = $1; }
			elsif (/^\s*MapVersion\s*=\s*(.+)/i)							{ $config_map_version = $1; }
			elsif (/^\s*InstallExtraPackages\s*=\s*(.+)/i)					{ $config_extra_packages = $1; }
			elsif (/^\s*ExtraPackages\s*=\s*(.+)/i)							{ $config_packages = $1; }
			elsif (/^\s*RepositoryUrl\s*=\s*(.+)/i)							{ $config_repository = $1; }
			
			elsif ( $_ =~ m/^$config_map_prefix/ )
			{
				push @Exclude_Rotation, $_;
			}
		}
	}
	close $fh;
}

