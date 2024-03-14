#!/usr/bin/perl -w
use strict;
#use List::MoreUtils qw(uniq);

my @names = ();
my @unique = ();
my @Exclude_Rotation = ();

my $config_names_file						    = "names.txt";
my $config_bot_file								= "bot_names.cfg";
my $config_prefix								= "";
my $config_remove_duplicates					= 1;
my $config_sort									= 1;
my $config_version								= 1.0;
my $config_export_directory 					="";
my $WHITESPACE = qr{\s*};
my $EMPTY_LINE = qr{^$WHITESPACE$};
my %seen;
my $bot_count = 0;

sub WriteCreate($$)
{
	my $file = shift;
	my $msg	= shift;
	open ( my $fh, '>' . $file );
	print $fh "$msg\n";
	close $fh;
}

sub Write_bot_File($$)
{
	my $file = shift;
	my $msg	= shift;
	open ( my $fh, '>>' . $file );
	print $fh "$msg\n";
	close $fh;
}

ReadConfig();
WriteCreate($config_bot_file,"NAmes");

print "---------------------------------------------\n";
print "Bot Names Generator V$config_version\n";
print "---------------------------------------------\n";




#read names.txt
open(my $names_fh, '<', $config_names_file) or die("Could not open $config_names_file");
while( my $line = <$names_fh>)  
{
	if ( $line !~ m/^\#/ && $line !~ m/^\s+$/ )
	{
		if ( $line =~ m{$EMPTY_LINE} || ! $seen{$line}++ )
		{
			chomp $line;
			$line =~ s/^\s+//;
			$line =~ s/\s+$//;
			push @names, $line;
		}
	}
}
close($names_fh);

#generate bot_names_cfg


	
my @unique_names = do { my %seen; grep { !$seen{$_}++ } @names };
if (!$config_remove_duplicates)
{
	print"duplicates\n";
	@unique_names = @names; 
}
my @sorted_names = sort @unique_names;
@sorted_names = @unique_names if !($config_sort);

foreach my $name (@sorted_names) 
{
	
	Write_bot_File($config_bot_file,"BotName$bot_count=$config_prefix$name");
	print "Name: $config_prefix$name\n";
	$bot_count++;
}

print "Done generating bot_names.cfg\n";

sleep(5);
exit (1);


sub ReadConfig
{
	my $configfile = "bot_names_generator.cfg";
	open ( my $fh, $configfile ) or die "bot_names_generator.cfg not found!";
	while ( <$fh> )
	{
		if ( $_ !~ m/^\#/ && $_ !~ m/^\s+$/ )
		{
			if 	  (/^\s*Names_File\s*=\s*(.+)/i)							{ $config_names_file= $1; }
			elsif (/^\s*Bot_File\s*=\s*(.+)/i)								{ $config_bot_file = $1; }
			elsif (/^\s*Prefix\s*=\s*(.+)/i)								{ $config_prefix= $1; }
			elsif (/^\s*Sort\s*=\s*(.+)/i)									{ $config_sort = $1; }
			elsif (/^\s*RemoveDuplicates\s*=\s*(.+)/i)						{ $config_remove_duplicates = $1; }
			elsif (/^\s*Export_Directory\s*=\s*(.+)/i)						{ $config_export_directory = $1; }
		}
	}
	close $fh;
}
