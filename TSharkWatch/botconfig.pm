#!/usr/bin/perl
#line 2 "botconfig.pm"

package botconfig;
use strict;

use File::HomeDir;

our $configfile								= "config.cfg";
our $config_botmode;

# IRC basic settings
our $config_botname;
our $config_botfullname						= "test";
our $config_ircserver;
our $config_ircport;
our $irc_adminChannel;
our $irc_adminChannel_key					= "";
our $irc_publicChannel						= "";
our $irc_publicChannel_key					= "";
our $irc_charsPerSecond						= 4000;
our $irc_prefixIRCMessages					= 0;		# Hidden config option
our $irc_showTeamMessages_PublicChan		= 0;

# IRC NickServ / Qauth settings
our $irc_nickserv_auth						= "";
our $irc_nickserv_name						= "Nickserv";
our $config_q_auth;
our $config_q_username;
our $config_q_password;
our $irc_operUser							= "";
our $irc_operPass							= "";


#Files
our $config_xproxy_log = "xxzxxx"; 


our @LogFiles; 


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
			if (/^\s*BotName\s*\=\s*(\S+)/i)							{ $config_botname = $1; }
			if (/^\s*IrcServer\s*\=\s*(\S+)/i)							{ $config_ircserver = $1; }
			if (/^\s*IrcPort\s*=\s*(\d+)/i)								{ $config_ircport = $1; }
			if (/^\s*ircAdminChannel\s*=\s*(\S+)/i ||
				/^\s*IrcChannel\s*=\s*(\S+)/i )							{ $irc_adminChannel = $1; }
			if (/^\s*ircAdminChannelKey\s*=\s*(\S+)/i ||
				/^\s*IrcChannelKey\s*=\s*(\S+)/i )						{ $irc_adminChannel_key = $1; }
			if (/^\s*ircPublicChannel\s*=\s*(\S+)/i)					{ $irc_publicChannel = $1; }
			if (/^\s*ircPublicChannelKey\s*=\s*(\S+)/i)					{ $irc_publicChannel_key = $1; }
			if (/^\s*ircCharsPerSecond\s*=\s*(\d+)/i)					{ $irc_charsPerSecond = $1; }

			# IRC NickServ / Qauth settings
			if (/^\s*Nickservname\s*=\s*(\S+)/i)						{$irc_nickserv_name = $1; }
			if (/^\s*Nickservauth\s*=\s*(.+)/i)							{$irc_nickserv_auth = $1; }
			if (/^\s*Qauth\s*=\s*(1|0)/i)								{$config_q_auth = $1; }
			if (/^\s*Qusername\s*=\s*(\S+)/i)							{$config_q_username = $1; }
			if (/^\s*Qpassword\s*=\s*(\S+)/i)							{$config_q_password = $1; }

			if ( /^\s*operAuthUser\s*=\s*(\S+)/i )						{ $irc_operUser = $1; }
			if ( /^\s*operAuthPass\s*=\s*(\S+)/i )						{ $irc_operPass = $1; }
			if ( /^\s*XproxyLog\s*=\s*(\S+)/i )							{ $config_xproxy_log = $1; }
			if ( /^\s*LogFile\d\s*=\s*(\S+)/i )							{ push (@LogFiles, $1); }
		}
	}


	# Give errors on variables which MUST be provided by the config file, and cannot
	# use default settings.
	my $config_error;
	$config_error .= "BotName " if (!$config_botname);
	$config_error .= "IrcServer " if (!$config_ircserver);
	$config_error .= "IrcPort " if (!$config_ircport);
	$config_error .= "ircAdminChannel " if (!$irc_adminChannel);
	$config_error .= "XproxyLog " if (!$config_xproxy_log);
	$config_error .= "Qauth " if (length($config_q_auth) == 0);
	if ($config_q_auth == 1)
	{
		$config_error .= "Qusername " if (!$config_q_username);
		$config_error .= "Qpassword " if (!$config_q_password);
	}
	
	print "sdffsdfsd $config_xproxy_log\n";

	if ($config_error)
	{
		main::console_output ( "[Config] ERROR: Missing config file option(s): $config_error" );
		sleep ( 10 );
		exit;
	}

	close $fh;
}

1;
