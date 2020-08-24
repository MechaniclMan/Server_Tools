#!/usr/bin/perl -w
use strict;
use Mapconfig;

my @maps = ();
my @themaps = ();
my $directory = './Maps';
my $install = "./Maps/Install.txt";
my $ttcfg = "./Maps/tt.cfg";
my $mydef;
my $author = $Mapconfig::config_author;
my $version = $Mapconfig::config_version;
my $packages = $Mapconfig::config_packages;
my $packageslength = length($packages);


print "\n";
print "4.0 Server Map Installer & TT.cfg Generator v1.0\n";
print "\n";

#Get Maps from maps folder
opendir (DIR, $directory) or die $!;
while (my $file = readdir(DIR)) 
{
	next if ($file =~ m/^\./);
	next if ($file !~ m/^.+\.mix$/);
	next if ($file =~ /\s/);
	next if ($file =~ m/^.+\..+\.mix$/);
	push (@maps, $file);
}
closedir(DIR);

if (!@maps)
{
	print "Maps folder contains no packages. Their is nothing to process.\n";
	sleep(5);
	exit (0);
}

#remove install file if it exists
#if ( -e $install) 
#{
#	unlink($install);
#}
open(INSTALL, ">$install") or die("Could not open Install.txt.");
close ( INSTALL );

#convert maps and create install file
foreach my $line ( @maps )
{
	print "Converting $line\n";
	system("PackageEditor.exe convert \"$directory.\/$line\" $version $author >> \"$directory.\/Install.txt\"");
    if ($? != 0) 
	{
		print "$line Failed to Convert!\n";
    }
}

print "\n";

#install packages
open(INSTALL, "<$install") or die("Could not open Install.txt.");
foreach my $line (<INSTALL>) 
{
	$line =~ s/[\$#@~!&*()\[\];.,:?^ `\\\/]+//g;
	if ( $line =~ m/packageeditorinstall(.+)'/ )
	{
		system("PackageEditor.exe install $1");
	}
}
close ( INSTALL );

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

print "Generating $ttcfg\n";

#generate tt.cfg
open(TTCFG, ">$ttcfg") or die("Could not open tt.cfg.");
print TTCFG "gameDefinitions:\n";
print TTCFG "{\n";
foreach my $line ( @themaps )
{
	$mydef = $line;
	$mydef =~ s/\.mix//i;	$mydef =~ s/c\&c_//i; $mydef =~ s/\.//i; $mydef =~ s/ //i;
	$line =~ s/\.mix//i;
	print TTCFG "	$mydef:\n";
	print TTCFG "	{\n";
	print TTCFG "		mapName = \"$line\";\n";
	if ( $packageslength > 2 )
	{
		print TTCFG "		packages = [\"$line\",$packages];\n";
	}
	else
	{
		print TTCFG "		packages = [\"$line\"];\n";
	}
	print TTCFG "	};\n";
}
print TTCFG "};\n";
print TTCFG "\n";
print TTCFG "rotation:\n";
print TTCFG "[\n";
foreach my $line ( @themaps )
{
	$mydef = $line;
	$mydef =~ s/\.mix//i;	$mydef =~ s/c\&c_//i; $mydef =~ s/\.//i; $mydef =~ s/ //i;
	if ( $themaps[$#themaps] eq $line )
	{
		print TTCFG "	\"$mydef\"\n";
	}
	else
	{
		print TTCFG "	\"$mydef\",\n";
	}
}
print TTCFG "];\n";
print TTCFG "\n";
print TTCFG "downloader:\n";
print TTCFG "{\n";
print TTCFG "	repositoryUrl = \"\";\n";
print TTCFG "};\n";
close ( TTCFG );

sleep(5);
exit (0);