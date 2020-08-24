#!/usr/bin/perl -w

use constant BR_VERSION => 1.54;
use constant BR_BUILD => 244;
use constant BR_COPYRIGHT_YEAR => "2003-2014";


use Time::HiRes qw(time);		# Used by POE to make alarms more accurate
use POE;
use POE::Kernel;
use POE::Session;
use POE qw/Wheel::FollowTail/;
use DBI;
use Encode::Byte;

use POE::Component::Client::TCP;
use POE::Filter::Stream;
use IO::Socket;


use strict;
use warnings;
use diagnostics;

use botconfig;
use IRC;

# Disable buffering on STDIN / STDOUT 
$| = 1;

# Main variables
our $start_time = time();



botconfig::init();
IRC::init();
#StartLog($botconfig::config_xproxy_log);


foreach my $file(@botconfig::LogFiles)
{
	StartLog($file);
}

sub StartLog
{
	my $filename = shift;
	my $dir = $filename;
	if ( $filename =~ /fds/i) {
		$dir = $filename;
		$filename = $dir . "renlog_" . get_date_time( "MM-DD-YYYY.txt" );
	}
	elsif ( $filename !~ /.+\..+/i)
	{
		console_output ( 'Invalid Log '.$filename, 1 );
		return;
	}

	if ( -e $filename )
	{
		my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks)
			= stat( $filename );

		if ( $size <= 20000000 )
		{
			console_output ( 'Beginning Log read for '.$filename.'('.$size.' bytes)...', 1 );

			open (FILE, "<" . $filename);
			while (<FILE>)
			{
				chomp $_;
				if ( $_ =~ "_GAMELOG" )
				{
					#my $gamelog_line = $_;
					#$gamelog_line =~ s/_GAMELOG\s//gi;
					#gamelog::parse_line($gamelog_line);
				}
			}

			close (FILE);
			console_output ( 'Finished.', 3 );
		}
		else
			{ console_output ( 'Log file ' .$filename. ' is too large ('.$size.' bytes) to back read' ); }
	}


	# Start file tail
	POE::Session->create
	( inline_states => {
		_start => sub {
			console_output ( 'Starting log follow thread. '.$filename );

			if (-e $filename)
			{
				$_[HEAP]->{wheel} = POE::Wheel::FollowTail->new(
					Filename   => $filename,
					InputEvent => 'got_line',
					ErrorEvent => 'got_error',
					SeekBack   => 1,
				);

				$_[HEAP]->{first} = 0;
			}
			else
			{
				# Try again in 5 seconds
				$_[HEAP]->{next_alarm_time} = int( time() ) + 5;
				$_[KERNEL]->alarm( tick => $_[HEAP]->{next_alarm_time} );
			}

			$_[KERNEL]->alias_set( $filename . "_tail" ); #set an alias to be able to call renew_wheel from the outside
		},
		got_line     => sub { parse_line($_[ARG0], $filename) },
		got_error    => sub { warn "$_[ARG0]\n" },
		stop_log => sub
		{

			$_[HEAP]->{rename} = 1;
			$_[HEAP]->{wheel} = undef;
			$_[KERNEL]->alias_remove( "ssgm_tail" );
			$_[KERNEL]->yield( "shutdown" );
		},
		renew_wheel => sub
		{
			$filename = $dir . "renlog_" . get_date_time( "MM-DD-YYYY.txt" ) if ( $filename =~ /fds/i);
			console_output ( "Looking for logfile $filename...", 1 );
			if (-e $filename)
			{
				console_output ( 'Found', 3 );

				$_[HEAP]->{wheel} = POE::Wheel::FollowTail->new(
					 Filename   => "$filename",
					 InputEvent => 'got_line',
					 ErrorEvent => 'got_error',
					 );
				$_[HEAP]->{first} = 0;
			}
			else
			{
				$_[HEAP]->{next_alarm_time2} = int( time() ) + 120;
				$_[KERNEL]->alarm( tick => $_[HEAP]->{next_alarm_time2} );
				console_output ( 'Not found! Will try again in 2 minutes', 3 );

			}		
		},
		_stop => sub
		{
			console_output ( $filename . ' log follow thread has stopped' );
		},
		tick => sub
		{
			#if ( modules::get_module( "ssgmlog" ) != 0 )
			#{
			$_[KERNEL]->yield( "renew_wheel" ); # renew wheel
			#}
		}
	} ); # End of POE::Session->create
}

sub parse_line
{
	my $input = shift; my $filename = shift;
	if ( $input =~ /^\[\d\d:\d\d:\d\d\]\s(.+)$/ ) { $input = $1; }
	if ( $input =~ m/^\s+$/ ) { return; }
	
	if ( $filename =~ /renlog/i) {
		if ( $input =~ m/^\w+ not found/
			|| $input =~ /^Logging on..../
			|| $input =~ /^Logging onto .+ Server/
			|| $input =~ /^Failed to log in/
			|| $input =~ /^Creating game channel/
			|| $input =~ /^Channel created OK/
			|| $input =~ /^Terminating game/ 
			|| $input =~ m/(.+?) mode active/g 
			|| $input =~ /Server Shutdown/ )
		{
			print "$input\n";
			IRC::ircmsg ( $input );
		}
	}
	else{
		print "$input\n";
		IRC::ircmsg ( $input );
	}
	
	undef $input;
	undef $filename;
}

# Start the kernel running.
$poe_kernel->run();


# Prints a message to the console with the timestamp of the message. It also supports messages
# made up of multiple parts sent one after the other, for instance 'Trying to do X...' followed
# by 'success' or 'failure', without adding newlines and extra timestamps. Note that a newline
# will automatically be output if a non-multipart message or a new multipart message is sent
# whilst expecting the continuation of another multipart message.
#
# Parameters
# Message					Message to be output to the console
# Multipart Type			1 for the start of a message, 2 for middle sections, 3 for end
my $console_output_multipart_status = 0;
sub console_output
{
	my $message = shift;
	my $multipart_type = shift;

	# If this is not a multipart message, the start of a new one, or a continuation of
	# one when we are not expecting a continuation, output timestamp
	if ( !defined($multipart_type) || $multipart_type == 1 || $console_output_multipart_status != 1 )
	{
		# If a current multipart message is in progress then end it now
		if ( $console_output_multipart_status == 1 )
			{ print "\n"; }

		# Get current timestamp
		my ($second,$minute,$hour,undef,undef,undef,undef,undef,undef)=localtime(time);

		# Output timestamp
		printf ( "[%02d:%02d:%02d] ",$hour,$minute,$second);

		# Set new multipart message status
		$console_output_multipart_status = ( defined($multipart_type) && $multipart_type == 1 ) ? 1 : 0;
	}

	# Output message
	print $message;

	# If this is not a multipart message, or the end of one, output newline
	if ( !defined($multipart_type) || $multipart_type == 3 )
	{
		print "\n";

		# Set new multipart message status
		$console_output_multipart_status = 0;
	}
}

sub display_error
{
	my $error = shift;
	return if (!$error);
	my $target = shift;

	if ( !defined($target) || $target eq 'b' || $target eq 'i' ) { 
	IRC::ircmsg ( "Runtime Error: $error", "A" );
	}
	if ( !defined($target) || $target eq 'b' || $target eq 'c' ) { 
	console_output ( "[ERROR] $error" );	
	}
}

# This routine gets the current date, and spits out
# the proper current logfile name we should be opening.
#
# You pass it a string (filename) and it automatically
# replaces MM DD YYYY HH MM SS with the current time digits.
sub get_date_time
{
	my $string = $_[0];

	my ($second,$minute,$hour,$day,$month,$year,$weekday,$yearday,$dst_flag)=localtime(time);

	$year  += 1900;
	my $year_short = substr ( $year, 2 );
	$month += 1;

	if ($second < 10) {$second ="0".$second;}
	if ($hour   < 10) {$hour   ="0".$hour;}
	if ($minute < 10) {$minute ="0".$minute;}

#	The actual substition of the matched strings for values.
	$string =~ s/YYYY/$year/;
	$string =~ s/YY/$year_short/;
	$string =~ s/DD/$day/;
	$string =~ s/MM/$month/;
	$string =~ s/ss/$second/;
	$string =~ s/hh/$hour/;
	$string =~ s/mm/$minute/;

	return $string;
}

sub get_linux_date_time
{
	my $string = $_[0];

	my ($second,$minute,$hour,$day,$month,$year,$weekday,$yearday,$dst_flag)=localtime(time);

	my $year_short = substr ( $year, 2 );

	if ($second < 10) {$second ="0".$second;}
	if ($hour   < 10) {$hour   ="0".$hour;}
	if ($minute < 10) {$minute ="0".$minute;}

#	The actual substition of the matched strings for values.
	$string =~ s/YYYY/$year/;
	$string =~ s/YY/$year_short/;
	$string =~ s/DD/$day/;
	$string =~ s/MM/$month/;
	$string =~ s/ss/$second/;
	$string =~ s/hh/$hour/;
	$string =~ s/mm/$minute/;

	return $string;
}

sub get_past_date_time
# This routine gets the current date, and spits out
# the proper current logfile name we should be opening.
#
# You pass it a string (filename) and it automatically
# replaces MM DD YYYY HH MM SS with the current time digits.
#
# !!This routine will not work without the Time::localtime function/module!!

{
	my $string = $_[0];
	my $timestamp = $_[1];


	my ($second,$minute,$hour, $day,$month,$year, $weekday,$yearday,$dst_flag)=localtime($timestamp);

	$year = $year + 1900;
	my $year_short = substr ( $year, 2 );
	$month++;

#   Convert single digits to double digits
#   ie "1" becomes "01".

	if ($month  < 10) {$month  ="0".$month;}
	if ($day	< 10) {$day	="0".$day;}
	if ($second < 10) {$second ="0".$second;}
	if ($hour   < 10) {$hour   ="0".$hour;}
	if ($minute < 10) {$minute ="0".$minute;}

#   The actual substition of the matched strings for values.
	$string =~ s/YYYY/$year/;
	$string =~ s/YY/$year_short/;
	$string =~ s/DD/$day/;
	$string =~ s/MM/$month/;
	$string =~ s/ss/$second/;
	$string =~ s/hh/$hour/;
	$string =~ s/mm/$minute/;

	return $string;
}