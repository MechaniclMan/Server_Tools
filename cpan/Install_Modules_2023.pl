

use strict;
use CPAN;

print "\n";
print "Installing Modules 2023\n";
print "\n";


#my @modules = ();
#push (@modules, $_);

#CPAN::Shell->install("POE");
#CPAN::Shell->install("POE::Kernel");
#CPAN::Shell->install("POE::Session");
#CPAN::Shell->install("POE::Component::Client::TCP");
#CPAN::Shell->install("POE::Filter::Stream");
#CPAN::Shell->install("Encode");
CPAN::Shell->install("Encode::Byte");
CPAN::Shell->install("Date::Calc");
CPAN::Shell->install("XML::Simple");
CPAN::Shell->install("Digest::MD5");
CPAN::Shell->install("Class::Unload");
CPAN::Shell->install("XML::Parser");
CPAN::Shell->install("Net::FTP");
CPAN::Shell->install("DBD::SQLite2");
CPAN::Shell->install("DBD::SQLite");
CPAN::Shell->install("DBD::mysql");
CPAN::Shell->install("Win32::Exe");
CPAN::Shell->install("Win32:GUI");
CPAN::Shell->install("Tie::STDOUT");
CPAN::Shell->install("Win32::Exe");
CPAN::Shell->install("Win32::Console");
CPAN::Shell->install("Win32::Process");
CPAN::Shell->install("Win32::Process::List");
CPAN::Shell->install("Win32::Process::Info");
CPAN::Shell->install("PAR:Packer");
CPAN::Shell->install("Net::SSLeay");
CPAN::Shell->install("Geo::IP");
CPAN::Shell->install("Geo::IP2Proxy");
CPAN::Shell->install("Net::IP");
CPAN::Shell->install("Net::Whois::IP");
CPAN::Shell->install("WWW::Shorten");
CPAN::Shell->install("WWW::Shorten::TinyURL");
CPAN::Shell->install("IRC::Toolkit::Colors");
#CPAN::Shell->install("Google::API::Client");
CPAN::Shell->install("Data::Dumper::Simple");
CPAN::Shell->install("Devel::Size");

CPAN::Shell->install("File::Copy;");
CPAN::Shell->install("File::NCopy");
CPAN::Shell->install("File::Path");
CPAN::Shell->install("Cwd");
CPAN::Shell->install("Archive::Zip");
CPAN::Shell->install("Exporter");

CPAN::Shell->install("Net");
CPAN::Shell->install("Net::SSH");
CPAN::Shell->install("Net::SSH::Perl;");
CPAN::Shell->install("Net::SSH::Putty");
CPAN::Shell->install("Net::OpenSSH");


print "Done Installing Modules!\n";

exit (0);