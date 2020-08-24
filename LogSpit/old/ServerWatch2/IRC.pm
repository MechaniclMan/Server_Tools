#line 1 "IRC.pm"
# brIRC.pm
#
# Connects to an IRC server and manages the sending and receiving of data on the
# IRC network.

package IRC;
use strict;

use IO::Socket;
use POE;


# Variables
my $socket;
my @Queue;			# Queue for outgoing messages

our %adminChannelUsers;		# Permission flags for admin channel users
our %publicChannelUsers;		# Permission flags for public channel users


# Connect to the IRC server, and join channels
sub init
{
	# Create IRC session
	POE::Session->create
	( inline_states =>
		{
			_start => sub
			{
				my ( $kernel, $heap ) = @_[ KERNEL, HEAP ];
				$kernel->alias_set( "IRC" );

				# Public and admin IRC channels cannot be the same
				if ( lc($botconfig::irc_publicChannel) eq lc($botconfig::irc_adminChannel) ) { $botconfig::irc_publicChannel = ""; };

				$socket = IO::Socket::INET->new( PeerAddr => $botconfig::config_ircserver,
					PeerPort => $botconfig::config_ircport,
					Proto => 'tcp' );


				if ( $socket && $socket->connected() )
				{
					main::console_output ( "[IRC] Connected to $botconfig::config_ircserver." );

					# Identify ourself to the server
					sendToServer ( "NICK $botconfig::config_botname" );
					sendToServer ( "USER $botconfig::config_botname * * :BRenBot ".main::BR_VERSION." build ".main::BR_BUILD );

					# Store current IRC nickname (used when resolving 433 (nick in use) problems)
					$heap->{'ircNick'} = $botconfig::config_botname;

					# Start receiving
					$kernel->yield( "receiveloop" );
					$kernel->yield( "sendloop" );
				}
				else
				{
					main::console_output ( "[IRC] Failed to connect to $botconfig::config_ircserver, retrying in 5 seconds." );
					$kernel->alarm ( "reconnect" => (time()+5) );
				}
				#$_[KERNEL]->alias_set( "IRC_Test" ); #set an alias to be able to call renew_wheel from the outsie
			},
			reconnect => sub
			{
				my ( $kernel, $heap ) = @_[ KERNEL, HEAP ];

				$socket = IO::Socket::INET->new( PeerAddr => $botconfig::config_ircserver,
					PeerPort => $botconfig::config_ircport,
					Proto => 'tcp' );

				if ( $socket && $socket->connected() )
				{
					main::console_output ( "[IRC] Connected to $botconfig::config_ircserver." );

					# Identify ourself to the server
					sendToServer ( "NICK $botconfig::config_botname" );
					sendToServer ( "USER BRenBot_$botconfig::config_botname * * :BRenBot ".main::BR_VERSION." build ".main::BR_BUILD );

					# Store current IRC nickname (used when resolving 433 (nick in use) problems)
					$heap->{'ircNick'} = $botconfig::config_botname;

					# Start receiving
					$kernel->yield( "receiveloop" );
					$kernel->yield ( "sendloop" );
				}
				else
				{
					main::console_output ( "[IRC] Failed to connect to $botconfig::config_ircserver, retrying in 30 seconds." );
					$kernel->alarm ( "reconnect" => (time()+30) );
				}
			},
			receiveloop => sub
			{
				my $heap = $_[ HEAP ];

				$heap->{'socket'} = new POE::Wheel::ReadWrite
				(
					Handle     => $socket,
					InputEvent => 'gotline',
					ErrorEvent => 'goterror',
			    );
			},
			sendloop => sub
			{
				my $kernel = $_[ KERNEL ];
				my $availableChars = $botconfig::irc_charsPerSecond;
				my $sendString = "";

				# Send at least one message
				if ( $Queue[0] )
				{
					my $output = shift @Queue;
					$sendString .= $output;
					$availableChars -= length ( $output );
				}

				# Keep sending messages until we hit out chars per second limit
				while ( $Queue[0] && ( length($Queue[0]) < $availableChars ) )
				{
					my $output = shift @Queue;
					$sendString .= $output;
					$availableChars -= length ( $output );
				}

				if ( $sendString )
				{
					$socket->send( $sendString );
				}

			    # Come back to the send loop in 1 second
			    $kernel->delay ( "sendloop", 1 );
			},
			gotline => sub
			{
				my ( $heap, $input ) = @_[ HEAP, ARG0 ];

				if ( $input =~ m/^PING\s(.+)$/i )
					{ sendToServer ( "PONG $1", 1 ); return; }

				if ( $input =~ m/^\:(\S+)\s001\s/ )
				{
					# If we have a NickServ auth line send it to the server
					if ( $botconfig::irc_nickserv_name && $botconfig::irc_nickserv_auth )
						{ ircpm ( $botconfig::irc_nickserv_name, $botconfig::irc_nickserv_auth ); }

					# If operAuth is enabled then send it off
					if ( $botconfig::irc_operUser && $botconfig::irc_operPass )
						{ sendToServer ( "OPER $botconfig::irc_operUser $botconfig::irc_operPass" ); }

					if ( $botconfig::irc_publicChannel ne "" )
					{
						main::console_output ( "[IRC] Joining channel $botconfig::irc_publicChannel..." );
						sendToServer ( "JOIN $botconfig::irc_publicChannel $botconfig::irc_publicChannel_key" );
					}
					main::console_output ( "[IRC] Joining channel $botconfig::irc_adminChannel..." );
					sendToServer ( "JOIN $botconfig::irc_adminChannel $botconfig::irc_adminChannel_key" );

					# Send messages to both irc channels and the FDS
					ircmsg ( "BRenBot ".main::BR_VERSION." reporting for duty! Type !help for a list of commands." );
				}

				# Reply to NAMES (353)
				elsif ( $input =~ m/^\:(\S+)\s353\s/ )
					{ names ( $input ); }

				# PRIVMSG
				elsif ( $input =~ m/PRIVMSG/ )
					{ privmsg ( $input ); }

				# MODE
				elsif ( $input =~ m/MODE/ )
					{ mode ( $input ); }

				# JOIN
				elsif ( $input =~ m/JOIN/ )
					{ ircjoin ( $input ); }

				# PART
				elsif ( $input =~ m/PART/ )
					{ part ( $input ); }

				# NICK
				elsif ( $input =~ m/NICK/ )
					{ nick ( $input ); }


				# Nickname in use (433)
				elsif ( $input =~ m/^\:(\S+)\s433\s/ )
				{
					main::console_output ( "[IRC] Nickname ".$heap->{'ircNick'}." is already in use, retrying with ".$heap->{'ircNick'}."_1" );
					$heap->{'ircNick'} = $heap->{'ircNick'}."_1";
					sendToServer ( "NICK ".$heap->{'ircNick'} );
					sendToServer ( "USER ".$heap->{'ircNick'}." * * :BRenBot ".main::BR_VERSION." build ".main::BR_BUILD );
				}
			},
			goterror => sub
			{
				# Means we are disconnected
				my ( $kernel, $heap, $error ) = @_[ KERNEL, HEAP, ARG0 ];

				# Shutdown socket and wheel
				$heap->{'socket'}->shutdown_input();
				$heap->{'socket'}->shutdown_output();
				delete $heap->{'socket'};
				shutdown ( $socket, 2 );

				main::console_output ( "[IRC] ERROR: $error" );
				main::console_output ( "[IRC] Disconnect detected, attemping to reconnect in 10 seconds." );
				$kernel->alarm ( "reconnect" => (time()+10) );
			},
			disconnect => sub
			{
				# Means we are disconnected
				my ( $kernel, $heap, $error ) = @_[ KERNEL, HEAP, ARG0 ];

				# Shutdown socket and wheel
				$heap->{'socket'}->shutdown_input();
				$heap->{'socket'}->shutdown_output();
				delete $heap->{'socket'};
				shutdown ( $socket, 2 );

				main::console_output ( "[IRC] Disconnect" );
			},
			privmsg => sub
			{
				# Duplicates old IRC functionality to allow older plugins to work. Most
				# will not use channel codes, but we will add the parameter anyway
				my ( $recipient, $message, $channelCode ) = @_[ ARG0, ARG1, ARG2 ];

				if ( $recipient !~ m/^\#/ )
					{ ircpm ( $recipient, $message ); }
				else
					{ ircmsg ( $message, $channelCode ); }
			}
		}
	);
}

sub irc_disconnect {$poe_kernel->post("IRC" => "disconnect" );	}

sub irc_start {	init(); }

# Send a line to the server
sub sendToServer
{
	my $line			= shift;
	push ( @Queue, "$line\r\n" );
}


# Process incoming messages
sub privmsg
{
	my $line = shift;

	if ( $line =~ m/\:(.+)\!(.+)\@(.+)\sPRIVMSG\s(\#?\S+)\s\:(.+)/ )
	{
		my $nick			= $1;
		my $nick_fullname	= $2;
		my $nick_location	= $3;
		my $channel			= $4;
		my $message			= $5;

		if ( $channel !~ m/^\#/ )
		{
			privmsg_pm ( $message, $nick );
			return;
		}

		my $channelCode;
		if ( lc($channel) eq lc($botconfig::irc_publicChannel) || lc($channel) eq lc($botconfig::irc_adminChannel) )
			{ $channelCode = ( lc($channel) eq lc($botconfig::irc_adminChannel) ) ? "A" : "P"; }
		else
			{ return; }

		#print "$nick ( $nick_fullname @ $nick_location ) said '$message' on $channel\n";

		if ($message =~ /(^\!\w+)\s*(\w*).*/)
		{
			#eval { commands::parsearg( $message, "$nick\@IRC", "N", $channelCode ) };
			#main::display_error($@) if $@;
		}
	}
}


# Handle private messages from users
sub privmsg_pm
{
	my $message		= shift;
	my $sender		= shift;
}


# Handle mode changes
sub mode
{
	my $input = shift;
	
	if ( $input =~ m/\:\S+\sMODE\s(\S+)\s(\+|\-)([o|v|h|q|a]+)\s(.+)/ )
	{
		my $channel		= $1;
		my $plusminus	= $2;
		my $modes		= $3;
		my $names		= $4;
		
		while ( $names =~ m/^(\S+)(\s(.+))?/ )
		{
			my $name = $1;
			$names = "";
			$names = $2 if ( $2 );
			$names=~s/^\s+//;
		
			$modes =~ m/^(\S)(\S+)?/;
			my $flag = $1;
			$modes = $2 if ( $2 );
			
			if ( lc($channel) eq lc($botconfig::irc_adminChannel) )
			{
				if ( $plusminus eq '-' ) { setUserFlag ( $name, 'A', $flag, 0 ); }
				elsif ( $plusminus eq '+' ) { setUserFlag ( $name, 'A', $flag, 1 ); }
			}
			elsif ( lc($channel) eq lc($botconfig::irc_publicChannel) )
			{
				if ( $plusminus eq '-' ) { setUserFlag ( $name, 'P', $flag, 0 ); }
				elsif ( $plusminus eq '+' ) { setUserFlag ( $name, 'P', $flag, 1 ); }
			}
			
			return if ( $names eq "" );
		}
	}
}


# Process JOIN
sub ircjoin
{
	my $input = shift;
	if ( $input =~ m/\:(.+)\!(.+)\@(.+)\sJOIN\s\:(\S+)/ )
	{
		my $name = $1;
		my $channel = $4;
		main::console_output ( "[IRC] $1 joined channel $4" );
		
		my $search = quotemeta $botconfig::config_botname;
		if ( $name =~ /$search.*/ && lc($channel) ne lc($botconfig::irc_adminChannel)
		&& lc($channel) ne lc($botconfig::irc_publicChannel) )
		{
			sendToServer ( "PART $channel" );
		}

		if ( lc($channel ) eq lc($botconfig::irc_adminChannel) )
			{ addUser ( $name, 'A' ); }
		elsif ( lc($channel ) eq lc($botconfig::irc_publicChannel) )
			{ addUser ( $name, 'P' ); }
	}
}


# Process PART
sub part
{
	my $input = shift;
	if ( $input =~ m/\:(.+)\!(.+)\@(.+)\sPART\s(\S+)/ )
	{
		main::console_output ( "[IRC] $1 left channel $4" );

		if ( lc($4) eq lc($botconfig::irc_adminChannel) )
			{ deleteUser( $1, 'A' ); }
		elsif ( lc($4) eq lc($botconfig::irc_publicChannel) )
			{ deleteUser( $1, 'P' ); }
	}
}


# Process NICK
sub nick
{
	my $input = shift;
	if ( $input =~ m/\:(.+)\!(.+)\@(.+)\sNICK\s\:(\S+)/ )
	{
		main::console_output ( "[IRC] $1 is now known as $4" );

		if ( exists ( $adminChannelUsers{lc($1)} ) )
		{
			$adminChannelUsers{lc($4)} = {
				'name' => lc($4),
				'voice' => $adminChannelUsers{lc($1)}->{'voice'},
				'halfop' => $adminChannelUsers{lc($1)}->{'halfop'},
				'op' => $adminChannelUsers{lc($1)}->{'op'},
				'founder' => $adminChannelUsers{lc($1)}->{'founder'},
				'protected' => $adminChannelUsers{lc($1)}->{'protected'}
			};
			deleteUser ( $1, 'A' ); }
		if ( exists ( $publicChannelUsers{lc($1)} ) )
		{
			$publicChannelUsers{lc($4)} = {
				'name' => lc($4),
				'voice' => $publicChannelUsers{lc($1)}->{'voice'},
				'halfop' => $publicChannelUsers{lc($1)}->{'halfop'},
				'op' => $publicChannelUsers{lc($1)}->{'op'},
				'founder' => $publicChannelUsers{lc($1)}->{'founder'},
				'protected' => $publicChannelUsers{lc($1)}->{'protected'}
			};
			deleteUser ( $1, 'P' );
		}
	}
}


# Process names list
sub names
{
	my $input = shift;
	if ( $input =~ m/\:\S+\s353\s\S+\s.\s(\S+)\s\:(.+)/ )
	{
		my $channel = $1;
		my $names = $2;

		while ( defined($names) && $names =~ m/^(\@|\%|\+|\&|\~)?(\S+)(\s(.+))?/ )
		{
			$names = $4;
			if ( lc($channel) eq lc($botconfig::irc_adminChannel) && $1 )
			{
				if ( !exists ( $adminChannelUsers{lc($2)} ) ) { addUser ( $2, 'A' ); }
				setUserFlag ( $2, 'A', $1, 1 );
			}
			elsif ( lc($channel) eq lc($botconfig::irc_publicChannel) && $1 )
			{

				if ( !exists ( $publicChannelUsers{lc($2)} ) ) { addUser ( $2, 'P' ); }
				setUserFlag ( $2, 'P', $1, 1 );
			}
		}
	}
}



###################################################
####
## General functions for outputting messages to the
## IRC channel
####
###################################################


# Channel codes determine which channels get the message.
# A = Only admin channel
# P = Only public channel
# Anything else goes to both channels
sub ircmsg
{
	my $message		= shift;
	my $channelCode	= shift;

	if ( $botconfig::irc_prefixIRCMessages == 1 )
		{ $message = "[BR] " . $message; }

	if ( !defined($channelCode) or $channelCode ne "P" )
		{ sendToServer ( "PRIVMSG $botconfig::irc_adminChannel :$message" ); }
	if ( (!defined($channelCode) or $channelCode ne "A") && $botconfig::irc_publicChannel ne "" )
		{ sendToServer ( "PRIVMSG $botconfig::irc_publicChannel :$message" ); }
}


# Send a message to a user
sub ircpm
{
	my $recipient	= shift;
	my $message		= shift;

	sendToServer ( "PRIVMSG $recipient :$message" );
}

sub ircpm_rcbot
{
	my $message	= shift;
	
	foreach my $key ( keys %adminChannelUsers )  
	{
		if ( $adminChannelUsers{$key}->{'protected'} == 1 && $adminChannelUsers{$key}->{'name'} eq "rcbot" )
		{
			sendToServer ( "PRIVMSG $adminChannelUsers{$key}->{'name'} :$message" );
			last;
		}
	}
}

sub ircpm_moderators
{
	my $message	= shift;
	
	foreach my $key ( keys %adminChannelUsers )  
	{
		if ( $adminChannelUsers{$key}->{'protected'} == 1 ||
		$adminChannelUsers{$key}->{'founder'} == 1 ||
		$adminChannelUsers{$key}->{'op'} == 1 ||
		$adminChannelUsers{$key}->{'halfop'} == 1 )
		{
			#sendToServer ( "PRIVMSG $key :$message" );
			sendToServer ( "NOTICE $key :$message" )
		}
	}
}


# Send a notice to a user
sub ircnotice
{
	my $recipient	= shift;
	my $message		= shift;

	sendToServer ( "NOTICE $recipient :$message" )
}



###################################################
####
## Code for managing irc users data
####
###################################################

sub addUser
{
	my $username = lc(shift);
	my $userchannel = shift;

	if ( $userchannel eq 'A' && !exists ( $adminChannelUsers{$username} ) )
	{
		$adminChannelUsers{$username} = {
			'name' => $username,
			'voice' => 0,
			'halfop' => 0,
			'op' => 0,
			'founder' => 0,
			'protected' => 0
		};
	}
	elsif ( $userchannel eq 'P' && !exists ( $publicChannelUsers{$username} ) )
	{
		$publicChannelUsers{$username} = {
			'name' => $username,
			'voice' => 0,
			'halfop' => 0,
			'op' => 0,
			'founder' => 0,
			'protected' => 0
		};
	}
}


sub deleteUser
{
	my $username = lc(shift);
	my $userchannel = shift;

	if ( $userchannel eq 'A' && exists ( $adminChannelUsers{$username} ) )
	{
		foreach my $k ( keys %{$adminChannelUsers{$username}} )
		{ delete $adminChannelUsers{$username}->{$k}; }
		delete $adminChannelUsers{$username};
	}
	elsif ( $userchannel eq 'P' && exists ( $publicChannelUsers{$username} ) )
	{
		foreach my $k ( keys %{$publicChannelUsers{$username}} )
		{ delete $publicChannelUsers{$username}->{$k}; }
		delete $publicChannelUsers{$username};
	}
}


sub setUserFlag
{
	my $username = lc(shift);
	my $userchannel = shift;
	my $flag = lc(shift);
	my $flagState = shift;

	#print "setting flag $flag to $flagState for $username on $userchannel\n";

	if ( $userchannel eq 'A' && exists ( $adminChannelUsers{$username} ) )
	{
		if ( $flag eq "+" || $flag eq "v" ) { $adminChannelUsers{$username}->{'voice'} = $flagState; }
		if ( $flag eq "%" || $flag eq "h" ) { $adminChannelUsers{$username}->{'halfop'} = $flagState; }
		if ( $flag eq "@" || $flag eq "o" ) { $adminChannelUsers{$username}->{'op'} = $flagState; }
		if ( $flag eq "~" || $flag eq "q" ) { $adminChannelUsers{$username}->{'founder'} = $flagState; }
		if ( $flag eq "&" || $flag eq "a" ) { $adminChannelUsers{$username}->{'protected'} = $flagState; }
	}
	elsif ( $userchannel eq 'P' && exists ( $publicChannelUsers{$username} ) )
	{
		if ( $flag eq "+" || $flag eq "v" ) { $publicChannelUsers{$username}->{'voice'} = $flagState; }
		if ( $flag eq "%" || $flag eq "h" ) { $publicChannelUsers{$username}->{'halfop'} = $flagState; }
		if ( $flag eq "@" || $flag eq "o" ) { $publicChannelUsers{$username}->{'op'} = $flagState; }
		if ( $flag eq "~" || $flag eq "q" ) { $publicChannelUsers{$username}->{'founder'} = $flagState; }
		if ( $flag eq "&" || $flag eq "a" ) { $publicChannelUsers{$username}->{'protected'} = $flagState; }
	}
	else
	{
		#ircmsg ("Adding user $username $userchannel $flag $flagState", "");
		addUser ( $username, $userchannel );
		setUserFlag	($username, $userchannel, $flag, $flagState ); 
	}
}



sub getUserPermissions
{
	my $username = lc(shift);
	my $userchannel = shift;

	# Strip @IRC from username if it exists
	$username =~ s/\@IRC//gi;

	if ( $userchannel eq "A" && exists ( $adminChannelUsers{$username} ) )
	{
		if ( $adminChannelUsers{$username}->{'protected'} == 1 )
			{ return 'irc_protected'; }
		if ( $adminChannelUsers{$username}->{'founder'} == 1 )
			{ return 'irc_founder'; }
		if ( $adminChannelUsers{$username}->{'op'} == 1 )
			{ return 'irc_op'; }
		if ( $adminChannelUsers{$username}->{'halfop'} == 1 )
			{ return 'irc_halfop'; }
		if ( $adminChannelUsers{$username}->{'voice'} == 1 )
			{ return 'irc_voice'; }
	}
	elsif ( $userchannel eq "P" && exists ( $publicChannelUsers{$username} ) )
	{
		if ( $publicChannelUsers{$username}->{'protected'} == 1 )
			{ return 'irc_protected'; }
		if ( $publicChannelUsers{$username}->{'founder'} == 1 )
			{ return 'irc_founder'; }
		if ( $publicChannelUsers{$username}->{'op'} == 1 )
			{ return 'irc_op'; }
		if ( $publicChannelUsers{$username}->{'halfop'} == 1 )
			{ return 'irc_halfop'; }
		if ( $publicChannelUsers{$username}->{'voice'} == 1 )
			{ return 'irc_voice'; }
	}

	# Default
	return "irc_normal";
}

# --------------------------------------------------------------------------------------------------

# Format the specified text with bold font
#
# \param[in] $message
#   Message to be formatted
sub bold
{
  return "".shift."";
}

# Format the specified text with the specified colour
#
# \param[in] $colour
#   Colour to format the message, either specified as a single colour or a colour and background
#   pair seperated by a comma
# \param[in] $message
#   Message to be formatted
sub colourise
{
  my $colour = shift;
  my $message = shift;

  return "$colour$message";
}
# Return true
1;