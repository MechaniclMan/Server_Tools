#!/usr/bin/perl
use strict;
use warnings;

use IPC::Open3 qw( open3 );
#use Memory::Usage;
#my $mu = Memory::Usage->new();
#use Proc::ProcessTable;


#my $pid = open3(undef,\*READ,undef,"ping 127.0.0.1");

$| = 1;
my @cmd = ('ping 127.0.0.1 -t');
open(my $command_pipe, '-|', @cmd) or die $!;
while (<$command_pipe>) {
   chomp;
   #if $_ =~ //
   #print("Got: <<<$_>>>\n");
   print("$_\n");
}
close($command_pipe);


#523  13.273888  72.233.69.4 -> 192.168.1.108 HTTP HTTP/1.1 200 OK  (PNG)  http.content_type == "image/png"  http.content

#   memusage subroutine
#
#   usage: memusage [processid]
#
#   this subroutine takes only one parameter, the process id for 
#   which memory usage information is to be returned.  If 
#   undefined, the current process id is assumed.
#
#   Returns array of two values, raw process memory size and 
#   percentage memory utilisation, in this order.  Returns 
#   undefined if these values cannot be determined.

sub memusage {
    my @results;
    my $pid = (defined($_[0])) ? $_[0] : $$;
    my $proc = Proc::ProcessTable->new;
    my %fields = map { $_ => 1 } $proc->fields;
    return undef unless exists $fields{'pid'};
    foreach (@{$proc->table}) {
        if ($_->pid eq $pid) {
            push (@results, $_->size) if exists $fields{'size'};
            push (@results, $_->pctmem) if exists $fields{'pctmem'};
        };
    };
    return @results;
}



#use IPC::Open2;
#open2 my $out, my $in, "C:/Users/ab29741/Tools/Test.bat" or die "could not run bc";
#foreach my $n ($out) {
#  print $n;
#}


#In general I use system, open, IPC::Open2, or IPC::Open3 depending on what I want to do. The qx// operator, while simple, is too constraining in its functionality to be very useful outside of quick hacks. I find open to much handier.
#system: run a command and wait for it to return

#Use system when you want to run a command, don't care about its output, and don't want the Perl script to do anything until the command finishes.
#doesn't spawn a shell, arguments are passed as they are

#system("command", "arg1", "arg2", "arg3");


#spawns a shell, arguments are interpreted by the shell, use only if you
#want the shell to do globbing (e.g. *.txt) for you or you want to redirect
#output

#system("command arg1 arg2 arg3");



#qx// or ``: run a command and capture its STDOUT

#Use qx// when you want to run a command, capture what it writes to STDOUT, and don't want the Perl script to do anything until the command finishes.


#arguments are always processed by the shell
#in list context it returns the output as a list of lines

#my @lines = qx/command arg1 arg2 arg3/;

#in scalar context it returns the output as one string

#my $output = qx/command arg1 arg2 arg3/;



#exec: replace the current process with another process.

#Use exec along with fork when you want to run a command, don't care about its output, and don't want to wait for it to return. system is really just

#sub my_system {
#    die "could not fork\n" unless defined(my $pid = fork);
#    return waitpid $pid, 0 if $pid; #parent waits for child
#    exec @_; #replace child with new process
#}

#You may also want to read the waitpid and perlipc manuals.
#open: run a process and create a pipe to its STDIN or STDERR

#Use open when you want to write data to a process's STDIN or read data from a process's STDOUT (but not both at the same time).

#read from a gzip file as if it were a normal file
#open my $read_fh, "-|", "gzip", "-d", $filename
#    or die "could not open $filename: $!";

#write to a gzip compressed file as if were a normal file
#open my $write_fh, "|-", "gzip", $filename
#    or die "could not open $filename: $!";





#IPC::Open2: run a process and create a pipe to both STDIN and STDOUT

#Use IPC::Open2 when you need to read from and write to a process's STDIN and STDOUT.

#use IPC::Open2;

#open2 my $out, my $in, "/usr/bin/bc"
#    or die "could not run bc";

#print $in "5+6\n";

#my $answer = <$out>;



#IPC::Open3: run a process and create a pipe to STDIN, STDOUT, and STDERR

#use IPC::Open3 when you need to capture all three standard file handles of the process. I would write an example, but it works mostly the same way IPC::Open2 does, but with a slightly different order to the arguments and a third file handle


1;