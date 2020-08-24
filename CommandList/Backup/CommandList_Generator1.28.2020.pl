# CommandList Version 2.1
# Created by Blacky

use strict;
use XML::Simple;
use XML::Parser;
use XML::SAX::PurePerl;
use Data::Dumper;
use File::HomeDir;
use Scalar::Util qw( reftype );


my $xml_config;
our %xml;
our $configfile			= "config.cfg";
our $config_file 		= "commands.txt";
our $config_log_file 	= "log.txt";
our $config_disabledfile = "disabled_commands.txt";
our $config_split		= 0;
our $config_sort		= 1;
our $config_unique		= 1;
our $config_show_alias = 1;
our $config_show_modlevel = 1;
our $config_show_plugin = 1;
our $config_hidecommands = 0;
our $config_hidecommand_showmodlevel = 0;
my $disabled_commands = 0;

PrintLog("------------------------------------------\n");
PrintLog("Brenbot CommandList Generator Tool V2.1\n");
PrintLog("------------------------------------------\n");
PrintLog("Run this when you edit BRenBot plugins.\n");
PrintLog("Run this when you edit Commands.xml.\n");
PrintLog("\n");

# Loads all config data
ReadConfig();

#delete existing files
unlink $config_file;
unlink $config_disabledfile;
unlink $config_log_file;

readXMLData();
my @commands = ();
my @commands_hash = ();
my @disabled_commands = ();
my @plugins = ();
my @mastercommands = ();
my @uniquecommands = ();
my @uniqueplugins = ();
my @uniquemaster = ();
@commands = get_commands($xml_config, "");
@plugins = get_plugins();

PrintLog("\n");

#if ( scalar(@commands) == 0 ) { PrintLog("ERROR no command's found check commands.xml.\n"; sleep(5); exit; }
if ( scalar(@commands) == 0 ) { PrintLog("ERROR no command's found check commands.xml.\n"); }
if ( scalar(@plugins) == 0 ) { PrintLog("No Plugin command's found.\n"); }

my @mastercommands = (@commands, @plugins);

if ( $config_unique == 1 )
{
	@uniquecommands = unique_commands(@commands);
	@uniqueplugins = unique_commands(@plugins);
	@uniquemaster = unique_commands_verbose(@mastercommands);
}

if ( scalar(@uniquecommands) == 0 ) { @uniquecommands = @commands;  }
if ( scalar(@uniqueplugins) == 0 ) { @uniqueplugins = @plugins; }
if ( scalar(@uniquemaster) == 0 ) { @uniquemaster = @mastercommands; }

my @sorted_commands = sort @uniquecommands; #sort alphabetically
my @sorted_plugins = sort @uniqueplugins; #sort alphabetically
my @sorted_master = sort @uniquemaster; #sort alphabetically

if ( $config_sort != 0 )
{
	@commands = @sorted_commands;
	@plugins = @sorted_plugins;
	@mastercommands = @sorted_master;
}
else
{
	@commands = @uniquecommands;
	@plugins = @uniqueplugins;
	@mastercommands = @uniquemaster;
}

# Sort by ModLevel
if ($config_sort == 2 ) 
{
	#Commands
	# Since the array element is a single string put the modlevel name in the front of the string so we can sort it by the modlevel
	@sorted_commands = ();
	@sorted_commands = ArrangeByType(\@commands, 2); #Pass array by Reference, type
	@sorted_commands = sort @sorted_commands;
	
	#Now that it is sorted by the modlevel create a new array with our original format
	@commands = ();
	@commands = ArrangeByType(\@sorted_commands, 2); #Pass array by Reference, type

	#Plugins
	# Since the array element is a single string put the modlevel name in the front of the string so we can sort it by the modlevel
	@sorted_plugins = ();
	@sorted_plugins = ArrangeByType(\@plugins, 2); #Pass array by Reference, type
	@sorted_plugins = sort @sorted_plugins;
	
	#Now that it is sorted by the modlevel create a new array with our original format
	@plugins = ();
	@plugins = ArrangeByType(\@sorted_plugins, 2); #Pass array by Reference, type
	
	#master
	# Since the array element is a single string put the modlevel name in the front of the string so we can sort it by the modlevel
	@sorted_master = ();
	@mastercommands = (@commands, @plugins);
	@sorted_master = ArrangeByType(\@mastercommands, 2);
	@sorted_master = sort @sorted_master;
	
	#Now that it is sorted by the modlevel create a new array with our original format
	@mastercommands = ();
	@mastercommands = ArrangeByType(\@sorted_master, 2);
	if ( $config_unique == 1 ) { @mastercommands = unique_commands(@mastercommands); }
}

# Sort by Plugin
if ($config_sort == 3 ) 
{
	# Since the array element is a single string put the plugin name in the front of the string so we can sort it by the plugin name
	@sorted_plugins = ();
	@sorted_plugins = ArrangeByType(\@plugins, 3); #Pass array by Reference, type
	@sorted_plugins = sort @sorted_plugins;
	
	#Now that it is sorted by the plugin name create a new array with our original format
	@plugins = ();
	@plugins = ArrangeByType(\@sorted_plugins, 3); #Pass array by Reference, type
	#print Dumper @plugins;
	
	@mastercommands = ();
	@mastercommands = (@commands, @plugins);
	@uniquemaster = @mastercommands;
	if ( $config_unique == 1 ) { @mastercommands = unique_commands(@uniquemaster); }
}

if ($config_sort == 4 ) 
{
	@commands = reverse @commands;
	@plugins = reverse @plugins;
	@mastercommands = reverse @mastercommands; #reverse array
}

if ( $disabled_commands > 0 ) { PrintLog("Disabled Commands: $disabled_commands\n"); }


if ( $config_hidecommands )
{
	WriteCreate($config_file, "[HideCommands]");
}
else 
{
	WriteCreate($config_file, "Generated by CommandList Version 2.1\n");
	WriteCreate($config_disabledfile, "Generated by CommandList Version 2.1\n");
}

if ( $config_split == 1 ) 
{
	WriteFile( $config_file, "" );
	WriteFile( $config_file, "-------------------------------------" );
	WriteFile( $config_file, "Commands" );
	WriteFile( $config_file, "-------------------------------------" );
	WriteFile( $config_file, "" );
	WriteCommands($config_file, @commands);
	WriteFile( $config_file, "" );
	WriteFile( $config_file, "-------------------------------------" );
	WriteFile( $config_file, "Plugins" );
	WriteFile( $config_file, "-------------------------------------" );
	WriteFile( $config_file, "" );
	WriteCommands($config_file, @plugins);
	WriteFile( $config_file, "-------------------------------------" );
	WriteFile( $config_file, "Disabled" );
	WriteFile( $config_file, "-------------------------------------" );
	WriteFile( $config_file, "" );
	WriteCommands($config_disabledfile, @disabled_commands);
}
else
{
	#print Dumper @mastercommands;
	WriteCommands($config_file, @mastercommands);
	WriteCommands($config_disabledfile, @disabled_commands);
}

PrintLog("\n");
PrintLog("Done Generating $config_file\n");

sleep(5);
PrintLog(Dumper(\@commands_hash));

sleep(5);
exit(1);


sub ArrangeByType
{
	my $array = shift;
	my $type = shift;
	my @sorted = ();
	foreach ( @$array )
	{
		my @entrys = split (";", $_);
		my $syntax		= $entrys[$type];
		my $modlevel	= $entrys[2];
		my $plugin		= $entrys[3];
		my $alias		= $entrys[4];
		
		if ( $type == 2 ) { $modlevel = $entrys[1]; }
		if ( $type == 3 ) { $plugin = $entrys[1]; }
		
		if ( defined($alias) ) { 
			push(@sorted, ";$syntax;$modlevel;$plugin;$alias");
		}
		else {
			push(@sorted, ";$syntax;$modlevel;$plugin;");
		}
	}
	return @sorted;
}

sub unique_commands_verbose
{
	my %seen;
	my @array = (@_);
	my @unique = ();
	foreach my $value (@array) 
	{
		my @entrys = split (";", $value);
		my $entry = $entrys[1];
		if ( $entry =~ /^(.+?)\s.+$/ ) 
		{
			my $command = $1;
			if (!defined($seen{$command})) { 
				push @unique, $value;
				$seen{$command} = 1;
			}
			else{
				PrintLog("Duplicate Command: $command\n");
			}
		}
		else{
			PrintLog("Command $entry syntax ERROR did not match command.\n");
		}
	}
	return @unique;
}

sub unique_commands
{
	my %seen;
	my @array = (@_);
	my @unique = ();
	my $command = undef;
	foreach my $value (@array) 
	{
		my @entrys = split (";", $value);
		my $entry = $entrys[1];
		if ( $entry =~ /^(.+?)\s.+$/ ) 
		{
			my $command = $1;
			if (!defined($seen{$command})) { 
				push @unique, $value;
				$seen{$command} = 1;
			}
		}
	}
	return @unique;
}

sub get_syntax_command_name($)
{
	my $syntax = shift;
	my $command = undef;
	if ( $syntax =~ /^(.+?)\s.+$/ || $syntax =~ /^(.+)$/ ) 
	{
		$command = $1;
	}
	else
	{
		PrintLog("Syntax get command failed $syntax\n");
	}
	return $command;
}

sub WriteCommands($)
{
	my $file = shift;
	my @array = (@_);
	foreach ( @array )
	{
		my @entrys = split (";", $_);
		my $syntax		= $entrys[1];
		my $modlevel	= $entrys[2];
		my $plugin		= $entrys[3];
		my $alias		= $entrys[4];
		
		if ( $syntax =~ /\s\>.+?\<\s/ ) 
		{
			PrintLog("Backwards Brackets Detected $syntax\n");
		}
		
		if ( $config_hidecommands == 0 ) 
		{
			WriteFile( $file, "!$syntax" );
			WriteFile( $file, "$alias" ) if ( defined($alias) && $config_show_alias == 1 );					
			WriteFile( $file, "$modlevel" ) if ( defined($modlevel) && $config_show_modlevel == 1);
			WriteFile( $file, "Plugin: $plugin" ) if ( defined($plugin) && $plugin ne "" && $config_show_plugin == 1 );
			WriteFile( $file, "" );
		}
		else
		{
			if ( $syntax =~ /^(.+?)\s.+$/ ) {
				if ( $config_hidecommand_showmodlevel == 1 ) {
					WriteFile( $file, '!'.$1." = 1 ;$modlevel" );
				}
				else
				{
					WriteFile( $file, '!'.$1." = 1 " );
				}
			}
			else{
				PrintLog("Command $syntax syntax ERROR did not match command.\n");
			}
		}
	}
}

sub readXMLData
{
	my $xmlOld = $xml_config;
	$xml_config = "";
	my $error;
	eval
	{
		PrintLog("Reading commands.xml \n");
		$xml_config = XMLin("commands.xml", ForceArray => [ 'group' ] );
		while ( my ($k, $v) = each %{$xml_config->{command}} )
		{
			$v->{syntax}->{value} =~ s/&gt;/>/gi;
			$v->{syntax}->{value} =~ s/&lt;/</gi;
		}
	}
	or $error = $@;
	if ( $error )
	{
		if ( ! -e "commands.xml")
		{
			PrintLog("commands.xml doesn't exist! commands.xml must be in the same folder as CommandList_Generator.exe.\n");
		}
		else
		{
			PrintLog("Error while reading commands.xml! \n");
			PrintLog("$error\n");
		}
		sleep(5);
		exit(1);
	}
}

sub get_plugins
{
	unless(opendir(DATADIR, "plugins/"))
	{
		PrintLog("No plugins folder found.\n");
		return ();
	}

	my @plugin_files;
	@plugin_files = grep(/\.pm$/i,readdir(DATADIR));
	my @mastercommands = ();

	foreach (@plugin_files)
	{
		my $plugin = $_;
		my $error;
		$plugin =~ s/\.pm$//g;
		PrintLog("Reading $plugin.xml\n");
		eval
		{
			$xml{$plugin} = XMLin( "plugins/$plugin.xml", ForceArray => [ qw(event group command hook) ], KeyAttr => [ 'name', 'key', 'id', 'event' ] );
		}
		or $error=$@;
		if ($error)
		{
			PrintLog("Error while reading $plugin.xml!");
			PrintLog("$error");
			next;
		}	
		@mastercommands = (@mastercommands, get_commands($xml{$plugin}, $plugin) );
	}
	return @mastercommands; 
}


#Fix script form crashing due to xml config error 
#Detects is value is Hash or Array, Think we have Duplicate Entry if an array. 
#Not to be used on 'group' or 'alias' as they are multi array config options. 
#'enabled' => [
#              {
#                'value' => '1'
#              },
#              {
#                'value' => '0'
#              }		
	 
sub DetectInvalidConfig($$$)
{
	my $key = shift;
	my $value = shift;
	my $c = shift;
	
	if ( ref($value) eq 'HASH' )
	{
		if ( ref($value->{enabled}) eq 'ARRAY' )
		{
			PrintLog("Duplicate xml entry detected $key enabled.\n");
			PrintLog(Dumper($value));
			return 1;
		}
		elsif ( ref($value->{syntax}) eq 'ARRAY' )
		{
			PrintLog("Duplicate xml entry detected $key syntax.\n");
			PrintLog(Dumper($value));
			return 1;
		}
		elsif ( ref($value->{help}) eq 'ARRAY' )
		{
			PrintLog("Duplicate xml entry detected $key help.\n");
			PrintLog(Dumper($value));
			return 1;
		}
		elsif ( ref($value->{hideInHelp}) eq 'ARRAY' )
		{
			PrintLog("Duplicate xml entry detected $key hideInHelp.\n");
			PrintLog(Dumper($value));
			return 1;
		}
		elsif ( ref($value->{permission}) eq 'ARRAY' )
		{
			PrintLog("Duplicate xml entry detected $key permission.\n");
			PrintLog(Dumper($value));
			return 1;
		}
	}
	else
	{
		PrintLog(Dumper($value));
		PrintLog("Invalid value detected $key $value.\n");
		return 1;
	
	}
	
	if ($key =~ /[A-Z]/ ) 
	{
        PrintLog("Warning uppercase config name detected $key\n");
    }
	
	my $command;
	my $syntax = $value->{syntax}->{value};
	$command = $1 if ( $syntax =~ /^(.+?)\s.+$/ );
	if ($syntax eq uc $syntax || $command =~ /[A-Z]/)
	{
        PrintLog("Warning uppercase syntax detected $syntax\n");
    }
	
	return 0;
}

sub get_commands($$)
{
	my $xml    = shift;
	my $plugin = shift;
	$plugin = "" if ( !defined($plugin) );

	my $c = $xml->{command};
	my @commands = ();
	my %seen;

	return if ( !defined($c) );
	while (my ($key, $value) = each %{$c})
	{
		next if DetectInvalidConfig($key,$value,$c);
		my $alias = "";
		my $syn = "$value->{syntax}->{value}";
		$syn =~ s/\!//g;
		my $sname = get_syntax_command_name($syn);
		my $slength = length($sname);
		my $temp = substr($sname, $slength + 1);
		$sname = lc($sname);
		$syn = $sname . $temp;
		my $syntax = "$syn - $value->{help}->{value}";
		
		if ( $value->{alias} )
		{
			$alias = "Command Alias: ";
			if ( ref($value->{alias}) eq "ARRAY" )
			{
				foreach ( @{$value->{alias}} )
				{
					my %alias = ( 'name' => $_, 'alias' => $key );
					$alias = $alias . "!" . $alias{name} . " ";
				}
			}
			else
			{
				my %alias = ( 'name' => $value->{alias}, 'alias' => $key );
				$alias = $alias . "!" . $alias{name} . " ";
			}
		}
		
		$alias = "" unless ( defined($alias) );
		
		my $permission = get_permission($value->{permission}->{level});
		my $modlevel = "Mod Level: $permission";
		
		#print 'Value:' . $value->{enabled}->{value};
		if ( defined($value->{enabled}->{value} ) )
		{
			my $enabled = $value->{enabled}->{value};
			if ( $enabled == 1 )
			{
				if ( defined($alias) ) 
				{ 
					push(@commands, ";$syntax;$modlevel;$plugin;$alias");
					#push @commands_hash, { syntax => $syntax, modlevel => $modlevel, plugin => $plugin, alias => $alias };
				}
				else 
				{
					push(@commands, ";$syntax;$modlevel;$plugin");
					#push @commands_hash, { syntax => $syntax, modlevel => $modlevel, plugin => $plugin };
				}
				
				push @commands_hash, { name => $sname, enabled => $enabled, syntax => $syntax, permission => $permission, plugin => $plugin, alias => $alias };
			}
			else
			{
				if ( defined($alias) ) 
				{ 
					push(@disabled_commands, ";$syntax;$modlevel;$plugin;$alias");
				}
				else 
				{
					push(@disabled_commands, ";$syntax;$modlevel;$plugin");
				}
				$disabled_commands++
			}
		}
	}
	return @commands;	
}

sub get_permission($)
{
	my $permission = shift;
	my $permission_name = "None";
	if ( $permission == 0 ) { $permission_name = "Normal Ingame Users"; }
	elsif ( $permission == 1 ) { $permission_name = "Temporary Moderators"; }
	elsif ( $permission == 2 ) { $permission_name = "Half Moderators"; }
	elsif ( $permission == 3 ) { $permission_name = "Full Moderators"; }
	elsif ( $permission == 4 ) { $permission_name = "Administrators"; }
	elsif ( $permission == 5 ) { $permission_name = "Administrators"; }
	return $permission_name;
}

sub ReadConfig
{
	my $fh;
	open ( $fh, $configfile ) or die "Config_File_Read: $!,";
	while ( <$fh> )
	{
		if ( $_ !~ m/^\#/ && $_ !~ m/^\s+$/ )		# If the line starts with a hash or is blank ignore it
		{
			if (/^\s*File\s*\=\s*(\S+)/i)								{ $config_file = $1; }
			if (/^\s*Disabled_File\s*\=\s*(\S+)/i)						{ $config_disabledfile = $1; }
			if (/^\s*Split\s*=\s*(\d+)/i)		 						{ $config_split = $1; }
			if (/^\s*Sort\s*=\s*(\d+)/i)		 						{ $config_sort = $1; }
			if (/^\s*UniqueCommands\s*=\s*(\d+)/i)						{ $config_unique = $1; }
			if (/^\s*Show_Alias\s*=\s*(\d+)/i)							{ $config_show_alias = $1; }
			if (/^\s*Show_ModLevel\s*=\s*(\d+)/i)						{ $config_show_modlevel = $1; }
			if (/^\s*Show_Plugin\s*=\s*(\d+)/i)							{ $config_show_plugin = $1; }
			if (/^\s*HideCommands\s*=\s*(\d+)/i)						{ $config_hidecommands = $1; } 
			if (/^\s*HideCommands_ShowModLevel\s*=\s*(\d+)/i)			{ $config_hidecommand_showmodlevel = $1; }
		}
	}

	my $config_error = undef;
	$config_error .= "File " unless ($config_file);
	if ($config_error)
	{
		PrintLog( "[Config] ERROR: Missing config file option(s): $config_error" );
		sleep ( 10 );
		exit;
	}

	close $fh;
}


sub PrintLog($)
{
	my $msg = shift;
	print($msg);
	chomp $msg;
	WriteFile($config_log_file, $msg);
}

sub WriteCreate($$)
{
	my $file = shift;
	my $msg	= shift;
	open ( my $fh, '>' . $file );
	print $fh "$msg\n";
	close $fh;
}

sub WriteFile($$)
{
	my $file = shift;
	my $msg	= shift;
	open ( my $fh, '>>' . $file );
	print $fh "$msg\n";
	close $fh;
}