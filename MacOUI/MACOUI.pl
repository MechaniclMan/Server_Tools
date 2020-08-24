#!/usr/bin/perl

# MACOUI v1.0
# Created by John
# Wireshark OUI database 2015
# process list of mac addresses 

use strict;
use warnings;

# Print header
print "\n  MAC address OUI lookup v1.0\n";

# Check arguments
if(	@ARGV > 1){
  print "  Too Many Arguments\n";
  print "  Usage: $0 [MACADDRESS]\n";
  print "  Syntax: macaddress [MACADDRESS]\n\n";
  exit;
}
elsif ( @ARGV == 0)
{
	my($input) = &promptUser("  Enter a macaddress or txt file ");
	$ARGV[0] = $input;
	chomp($ARGV[0]);
}
else{
	chomp($ARGV[0]);
}  


if ( $ARGV[0] =~ /^(.+\.txt)$/i)
{
	my $file = $1;
	#print "This is a text file\n";
	ProcessFile($file);
}
else{
	ProcessMacAddress($ARGV[0]);
}

sub ProcessFile
{
	my $file = shift;
	open my $ouifile, $file or die "Could not open $file: $!";

	while( my $line = <$ouifile>)  {
		if ( $line !~ m/^#.+$/i)
		{
			ProcessMacAddress($line);
		}
	}
	
	close $ouifile;
}


sub ProcessMacAddress
{
	my $input = shift;
	my $OUI;
	my $match = 0;
	
	# Removing seperators from MAC address and uppercase chars
	$input =~ s/[:|\s|-]//g;
	$input =~ y/a-z/A-Z/;

	# Get OUI from MAC
	if ($input =~ /^([0-9a-f]{6})/i) {
	  $OUI = $1;
	  print "  Checking OUI: ".$OUI."\n";
	} else {
	  &error($input);
	  return;
	}


	
	my $file = 'OUI.txt';
	open my $ouifile, $file or die "Could not open $file: $!";

	while( my $line = <$ouifile>)  {
		if ( $line !~ m/^#.+$/i)
		{
			if ( $line =~ m/^([0-9a-f]{6})\s(.+)\s#\s(.+)$/i ||
			$line =~ m/^([0-9a-f]{6})\s(.+)$/i)
			{
				my $checkoui = $1; my $company = $2; my $companydetail = $3;
				$company =~ s/\s//g;
				#print "$checkoui . $company . $companydetail . $OUI\n"; 
				if ($OUI eq $checkoui) {
					$companydetail = $company if (!$companydetail); 
					print "  Found OUI: ".$OUI." - ".$companydetail."\n\n";
					$match = 1;
				}		
			} 
			#Well-known addresses.
			#01-80-C2-00-00-45	TRILL-End-Stations
			else 
			{
				#$line =~ m/^([0-9a-f]{6})\s(.+)\s#\s(.+)$/i;
				#print $line."\n";
				#$line =~ m/^([0-9a-f]{6})\s(.+)\s#\s(.+)$/i
			}
				
		}
	}
	close $ouifile;
	
	# Show if OUI was not found
	
	print "  Could not find OUI: ".$OUI."\n\n" if ($match == 0 );
}


sub promptUser 
{
	our $promptString;
	local($promptString) = @_;
	print $promptString, ": ";
	$| = 1;               # force a flush after our print
	$_ = <STDIN>;         # get the input from STDIN (presumably the keyboard)
	chomp;
	return $_;
}

# Error messages
sub syntax
{
  print "  Usage: macaddress <maccaddress>.\n".
        "    Usage: perl MACOUI.pl <MAC/OUI>\n".
        "    MAC Format:\n".
        "       001122334455\n".
        "       00:11:22:33:44:55\n".
        "       00-11-22-33-44-55\n".
        "    OUI Format:\n".
        "       001122\n".
        "       00:11:22\n".
        "       00-11-22\n\n";
  exit;
}

sub error 
{
	my $input = shift;
  print "  Error: No MAC address or OUI specified or invalid for $input.\n".
        "    Usage: perl OUI_lookup.pl <MAC/OUI>\n".
        "    MAC Format:\n".
        "       001122334455\n".
        "       00:11:22:33:44:55\n".
        "       00-11-22-33-44-55\n".
        "    OUI Format:\n".
        "       001122\n".
        "       00:11:22\n".
        "       00-11-22\n\n";
}