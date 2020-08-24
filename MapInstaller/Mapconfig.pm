#!/usr/bin/perl
#line 2 "Mapconfig.pm"

package Mapconfig;
use strict;

our $config_author						= "MapInstaller";
our $config_packages					= "";
our $config_version						= 1.0;


ReadConfig();

sub ReadConfig
{
	my $fh;
	my $configfile = "MapInstaller.cfg";
	open ( $fh, $configfile ) or die "MapInstaller.cfg not found!";
	while ( <$fh> )
	{
		if ( $_ !~ m/^\#/ && $_ !~ m/^\s+$/ )
		{

			# IRC basic settings
			if (/^\s*MapAuthor\s*=\s*(.+)/i)								{ $config_author = $1; }
			if (/^\s*ExtraPackages\s*=\s*(.+)/i)							{ $config_packages = $1; }
			if (/^\s*MapVersion\s*=\s*(.+)/i)								{ $config_version = $1; }

		}
	}

	close $fh;
}







1;