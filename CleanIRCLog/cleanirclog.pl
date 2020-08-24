#!/usr/bin/perl
package cleanirclog;
use strict;
use Parse::IRCLog;

my $PLAYERDATA;
open(PLAYERDATA, ">./cleanlog.txt") or die("Could not open log file.");

my $result = Parse::IRCLog->parse("#Rc-mods.20150501.log");

my %to_print = ( msg => 1, action => 1 );

print PLAYERDATA "Test\n";

for ($result->events) {
my $line = "$_->{text}";
chomp $line;
#$line =~ s/\^.{1,7}?m//g;
#'s/\x1b\[[0-9;]*m//g'
#$line = s/\x1b\[[0-9;]*m//g;
#$line =~ s/[^a-zA-Z0-9{}\[\]\s]*//g;
#[May 01] {023754} 13[0900RCBOT13] 03
#$line =~ s/[^a-zA-Z0-9{}\[\]\(\)\/\s]*//g;
#[May 01] {022900} 13[0900RCBOT13] 03[TRIGGERBOT]08 
#if ( $line =~ m/^\[.+\]\s\{.+\}\s\d\[.+\]\s\d(\[.+\])\d\s(.+)/ ) {
#$line =~ s/[^a-zA-Z0-9{}\[\]\s]*//g;
#[May 01] {023754} 13[0900RCBOT13] 03
#$line =~ s/[^a-zA-Z0-9{}\[\]\(\)\/\s]*//g;
#[May 01] {022900} 13[0900RCBOT13] 03[TRIGGERBOT]08 
#if ( $line =~ m/^\[.+\]\s\{.+\}\s\d\[.+\]\s\d(\[.+\])\d\s(.+)/ ) {
#if ( $line =~ m/\d{2}(\[.+\])\d(.+)/ ) {
$line =~ s/\cC\d{1,2}(?:,\d{1,2})?|[\cC\cB\cI\cU\cR\cO\c_]//g;
#if ( $line =~ m/(\[.+\] \{.+\}).+(\[.+\])(.+)/ ) {
#$line = "$1 $2$3";
#print PLAYERDATA "$line\n";
#}
print PLAYERDATA "$line\n";


}


close ( PLAYERDATA );
print "Done\n";
