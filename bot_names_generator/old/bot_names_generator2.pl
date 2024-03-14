#!/usr/bin/perl -w
use strict;
use List::MoreUtils qw(uniq);

my @names = ();
my @unique = ();
my @Exclude_Rotation = ();

my $config_names_file						    = "names.txt";
my $config_bot_file								= "bot_names.cfg";
my $config_packages								= "";
my $config_version								= 1.0;
my $config_export_directory 					="";
my $WHITESPACE = qr{\s*};
my $EMPTY_LINE = qr{^$WHITESPACE$};
my %seen;


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
print "Bot Names Generator v$config_version\n";
print "---------------------------------------------\n";

my $bot_count = 0;
#my $names_fh = 0;
#generate bot_names_cfg
open(my $names_fh, '<', $config_names_file) or die("Could not open $config_names_file");
while( my $line = <$names_fh>)  
{   
    #print "Name: $line\n";
	#print "name:$_\n";
	if ( $line !~ m/^\#/ && $line !~ m/^\s+$/ )
	{
		#Write_bot_File($config_bot_file,"BotName$bot_count=$line\n");
		if ( $line =~ m{$EMPTY_LINE} || ! $seen{$line}++ )
		{
			#push @names, "BotName$bot_count=$line";
			chomp $line;
			push @names, $line;
			#$bot_count++;
		}
	}
}
close($names_fh);



#my @sorted_names = sort @names;
#my @unique = do { my %seen; grep { !$seen{$_}++ } @sorted_names };

sub uniq2 {
my %seen;
grep !$seen{$_}++, @_;
}

sub uniq3{
my %temp_hash = map { $_, 0 } @_;
return keys %temp_hash;
}

sub uniq4
{
	my @array = shift;
	my @new_array = ();
	foreach my $x (@array){
        push @new_array, $x if !grep{$_ eq $x}@new_array;
	}
	return @new_array;
}

sub uniq5 {
    my %seen;
    grep !$seen{$_}++, @_;
}

sub uniqueentr
{
	return keys %{{ map { $_ => 1 } @_ }};
}

sub unique {
    my %array;
    grep !$array{$_}++, @_;
}


my @result = ( $a[0] );
my $last = $a[0];
foreach (sort @a)
{
    push (@result, ($last = $_)) if ($_ ne $last);
}

my @unique=uniq(@names);
#my @unique_names=unique(@unique);
my @unique_names = do { my %seen; grep { !$seen{$_}++ } @unique };
my @sorted_names = sort @unique_names;
foreach my $name (@sorted_names) 
{
	print "Name: $name\n";
	Write_bot_File($config_bot_file,"BotName$bot_count=$name");
	$bot_count++;
}

print "End\n";

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
			elsif (/^\s*Export_Directory\s*=\s*(.+)/i)						{ $config_export_directory = $1; }
		}
	}
	close $fh;
}

