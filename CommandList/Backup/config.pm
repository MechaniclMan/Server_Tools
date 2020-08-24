#!/usr/bin/perl
#line 2 "config.pm"

package config;
use strict;
use File::HomeDir;

our $configfile			= "config.cfg";
our $config_sort		= 0;
our $config_unique		= 0;

# Loads all config data
sub init
{
	ReadConfig();
}

sub ReadConfig
{
	my $fh;
	open ( $fh, $configfile ) or die "Config_File_Read: $!,";
	while ( <$fh> )
	{
		if ( $_ !~ m/^\#/ && $_ !~ m/^\s+$/ )		# If the line starts with a hash or is blank ignore it
		{
			if (/^\s*Sort\s*\=\s*(\S+)/i)								{ $config_sort = $1; }
			if (/^\s*UniqueCommands\s*=\s*(\d+)/i)						{ $config_unique = $1; }
		}
	}


	# Give errors on variables which MUST be provided by the config file, and cannot
	# use default settings.
	my $config_error;
	$config_error .= "Sort " if (!$config_sort);
	$config_error .= "IrcServer " if (!$config_unique);
	$config_error .= "UniqueCommands " if (!$config_ircport);
	if ($config_error)
	{
		main::console_output ( "[Config] ERROR: Missing config file option(s): $config_error" );
		sleep ( 10 );
		exit;
	}

	close $fh;
}

1;
