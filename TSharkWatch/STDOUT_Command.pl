#!/usr/bin/perl -w

use constant BR_VERSION => 1.0;
use constant BR_BUILD => 1;
use constant BR_COPYRIGHT_YEAR => "2003-2016";


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
use threads;

# Disable buffering on STDIN / STDOUT 
$| = 1;

# Main variables
our $start_time = time();
our $ircstatus = 0;

botconfig::init();
IRC::init();
main::Test123();


sub Test123
{
	threads->create(sub { 
        my $thr_id = threads->self->tid;
        print "Starting thread $thr_id\n";
		sleep 20;
		$| = 1;
		my @cmd = ('X:\Users\Blackstar\Desktop\TSharkWatch\Wireshark\tshark.exe -i 4');
		open(my $command_pipe, '-|', @cmd) or die $!;
		while (<$command_pipe>) {
		   chomp;
		   #if $_ =~ //
		   #print("Got: <<<$_>>>\n");
		   #Print_Window($_);
		   IRC::ircmsg ( $_ );
		   #print("$_\n");
		}
		close($command_pipe);
        print "Ending thread $thr_id\n";
        threads->detach(); #End thread.
    });
}

# Start the kernel running.
$poe_kernel->run();


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