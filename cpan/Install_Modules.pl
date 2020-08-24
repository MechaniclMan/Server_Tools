

use strict;
use CPAN;

print "\n";
print "Installing Modules\n";
print "\n";


#my @modules = ();
#push (@modules, $_);

CPAN::Shell->install("POE");
CPAN::Shell->install("POE::Kernel");
CPAN::Shell->install("POE::Session");
CPAN::Shell->install("Encode");
CPAN::Shell->install("Date::Calc");
CPAN::Shell->install("XML::Simple");
CPAN::Shell->install("Digest::MD5");
CPAN::Shell->install("Class::Unload");
CPAN::Shell->install("XML::Parser");
CPAN::Shell->install("Net::FTP");
CPAN::Shell->install("PAR:Packer");
CPAN::Shell->install("DBD::SQLite2");
CPAN::Shell->install("DBD::SQLite");
CPAN::Shell->install("DBD::mysql");
CPAN::Shell->install("Win32::Exe");
CPAN::Shell->install("Win32:GUI");
CPAN::Shell->install("Tie::STDOUT");
CPAN::Shell->install("Win32::Console");
CPAN::Shell->install("Win32::Process::List");
CPAN::Shell->install("Win32::Process::Info");
CPAN::Shell->install("Net::SSLeay");
CPAN::Shell->install("Geo::IP");
CPAN::Shell->install("Geo::IP2Proxy");
CPAN::Shell->install("Net::IP");
CPAN::Shell->install("Net::Whois::IP");
CPAN::Shell->install("WWW::Shorten");
CPAN::Shell->install("Google::API::Client");
CPAN::Shell->install("Data::Dumper::Simple");
CPAN::Shell->install("Devel::Size");




print "Done Installing Modules!\n";

exit (0);