# CommandList Version 2.2
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
our $configfile			= "command_list.cfg";
our $config_file 		= "commands.txt";
our $config_log_file 	= "log.txt";
our $config_debug_file 	= "debug.txt";
our $config_disabledfile = "disabled_commands.txt";
our $config_split		= 0;
our $config_sort		= 1;
our $config_sort_alphabetically=1;
our $config_sort_modlevel=0;
our $config_sort_permission=0;
our $config_sort_plugin=1;
our $config_sort_reverse=1;

our $config_unique		= 1;
our $config_show_name = 1;
our $config_show_alias = 1;
our $config_show_syntax = 1;
our $config_show_help = 1;
our $config_show_modlevel = 1;
our $config_show_plugin = 1;
our $config_hidecommands = 0;
our $config_hidecommand_showmodlevel = 0;
my $disabled_command_count = 0;
my $command_count = 0;

PrintLog("------------------------------------------\n");
PrintLog("Brenbot CommandList Generator Tool V2.2\n");
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
my @disabled_commands = ();
my @plugins = ();
my @master_commands = ();
my @unique_commands = ();
my @unique_plugins = ();
my @unique_master = ();
my @sorted_commands = ();
my @sorted_plugins = ();
my @sorted_master = ();

@commands = get_commands($xml_config, "None");
@plugins = get_plugins();
@master_commands = (@commands, @plugins);
PrintLog("\n");

if ( scalar(@commands) == 0 ) { PrintLog("ERROR no command's found check commands.xml.\n"); die;}
if ( scalar(@plugins) == 0 ) { PrintLog("No Plugin command's found.\n");}

if ( $config_unique == 1 )
{
	@unique_commands = unique_hash(@commands);
	@unique_plugins = unique_hash(@plugins);
	@unique_master = unique_hash_verbose(@master_commands);
}
else
{
	@unique_commands = @commands;
	@unique_plugins = @plugins;
	@unique_master = @master_commands;
}

if ( scalar(@unique_commands) == 0 ) { @unique_commands = @commands;  }
if ( scalar(@unique_plugins) == 0 ) { @unique_plugins = @plugins; }
if ( scalar(@unique_master) == 0 ) { @unique_master = @master_commands; }

if ( $config_sort )
{
	@sorted_commands = @unique_commands;
	@sorted_plugins = @unique_plugins;
	@sorted_master = @unique_master;
	
	if ($config_sort_alphabetically) 
	{
		@sorted_commands =  sort {  $a->{name} cmp $b->{name} } @unique_commands; #sort name alphabetically
		@sorted_plugins = sort {  $a->{name} cmp $b->{name} } @unique_plugins; #sort name alphabetically
		@sorted_master = sort {  $a->{name} cmp $b->{name} } @unique_master; #sort name alphabetically
		
		@unique_commands = @sorted_commands;
		@unique_plugins = @sorted_plugins;
		@unique_master = @sorted_master;
	}
	# Sort by ModLevel
	if ($config_sort_modlevel) 
	{
		#Commands
		#@sorted_commands = ();
		@sorted_commands = sort {  $a->{permission} cmp $b->{permission} } @unique_commands;

		#Plugins
		#@sorted_plugins = ();
		@sorted_plugins = sort {  $a->{permission} cmp $b->{permission} } @unique_plugins;
		
		#master
		#@sorted_master = ();
		@unique_master = ();
		@unique_master = (@sorted_commands, @sorted_plugins);
		@sorted_master =  sort {  $a->{permission} cmp $b->{permission} } @unique_master;
		
		@unique_commands = @sorted_commands;
		@unique_plugins = @sorted_plugins;
		@unique_master = @sorted_master;
	}
	# Sort by Plugin
	if ($config_sort_plugin) 
	{
		@unique_commands = unique_hash(@commands);
		@unique_plugins = unique_hash(@plugins);
		@sorted_commands =  sort {  $a->{name} cmp $b->{name} } @unique_commands;
		@sorted_plugins = sort {  $a->{plugin} cmp $b->{plugin} } @unique_plugins;
		@sorted_master = (@sorted_commands, @sorted_plugins);
		
		@unique_commands = @sorted_commands;
		@unique_plugins = @sorted_plugins;
		@unique_master = @sorted_master;
	}
	if ($config_sort_reverse) 
	{
		@sorted_commands = reverse @unique_commands;
		@sorted_plugins = reverse @unique_plugins;
		@sorted_master = reverse @unique_master; #reverse array
		
		@unique_commands = @sorted_commands;
		@unique_plugins = @sorted_plugins;
		@unique_master = @sorted_master;
	}
}

if ( scalar(@sorted_commands) == 0 ) { @sorted_commands = @unique_commands;  }
if ( scalar(@sorted_plugins) == 0 ) { @sorted_plugins = @unique_plugins; }
if ( scalar(@sorted_master) == 0 ) { @sorted_master = @unique_master; }


@commands = ();
@plugins = ();
@master_commands = ();
@unique_commands = ();
@unique_plugins = ();
@unique_master = ();


if ( $command_count > 0 ) { PrintLog("Enabled Commands: $command_count\n"); }
if ( $disabled_command_count > 0 ) { PrintLog("Disabled Commands: $disabled_command_count\n"); }


if ( $config_hidecommands )
{
	WriteCreate($config_file, "[HideCommands]");
}
else 
{
	WriteCreate($config_file, "Generated by CommandList Version 2.2\n");
	WriteCreate($config_disabledfile, "Generated by CommandList Version 2.2\n");
}

if ( $config_split == 1 && $config_hidecommands != 1) 
{
	WriteFile( $config_file, "" );
	WriteFile( $config_file, "-------------------------------------" );
	WriteFile( $config_file, "Commands" );
	WriteFile( $config_file, "-------------------------------------" );
	WriteFile( $config_file, "" );
	WriteCommandsRef($config_file, \@sorted_commands);
	WriteFile( $config_file, "" );
	WriteFile( $config_file, "-------------------------------------" );
	WriteFile( $config_file, "Plugins" );
	WriteFile( $config_file, "-------------------------------------" );
	WriteFile( $config_file, "" );
	WriteCommandsRef($config_file, \@sorted_plugins);
	WriteFile( $config_file, "-------------------------------------" );
	WriteFile( $config_file, "Disabled" );
	WriteFile( $config_file, "-------------------------------------" );
	WriteFile( $config_file, "" );
	WriteCommandsRef($config_file, \@disabled_commands);
}
else
{
	#print Dumper @master_commands;
	WriteCommandsRef($config_file, \@sorted_master);
	WriteCommandsRef($config_disabledfile, \@disabled_commands);
}

PrintLog("\n");
PrintLog("Done Generating $config_file\n");

sleep(5);
exit(1);



sub unique_hash
{
	my %seen;
	my @array = (@_);
	my @unique = ();
	my $command;
	
	foreach my $k (@array) 
	{
		if ( $k->{name} )
		{
			if (!defined($seen{$k->{name}})) { 
				push @unique, $k;
				$seen{$k->{name}} = 1;
			}
		}
	}
	return @unique;
}

sub unique_hash_verbose
{
	my %seen;
	my %last;
	my @array = (@_);
	my @unique = ();
	my $entry;
	my $dup = 0;
	my $end;
	
	foreach my $k (@array) 
	{
		if ( $k->{name} )
		{
			$entry = 1;
			$end = "Command Disabled" if ( $k->{enabled} != 1 );
			
			if (!defined($seen{$k->{name}})) { 
				push @unique, $k;
				$seen{$k->{name}} = 1;
				$last{$k->{name}} = $k->{plugin};
			}
			else
			{
				$dup++;
				if (defined($last{$k->{name}})) 
				{ 
					my $l = $last{$k->{name}};
					PrintLog("Duplicate Command: $k->{name} Plugin: $k->{plugin} Fist seen in [$l] $end\n");
				}
				else
				{
					PrintLog("Duplicate Command: $k->{name} Plugin: $k->{plugin}\n $end");
				}
			}
		}
	}
	PrintLog("\n") if($entry);
	PrintLog("Duplicate Count: $dup\n") if($dup != 0);
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
		return undef;
	}
	return $command;
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
	my @plugin_commands;
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
		@plugin_commands = (@plugin_commands, get_commands($xml{$plugin}, $plugin) );
	}
	return @plugin_commands; 
}


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
	if ($syntax eq uc $syntax || $command =~ /^[A-Z]/)
	{
        PrintLog("Warning uppercase syntax detected $syntax\n");
    }
	if( $syntax =~ /\s\>.+?\<\s/ ) 
	{
		PrintLog("Backwards Brackets Detected $syntax\n");
	}
	if( $syntax !~ /^!.+?$/ ) 
	{
		PrintLog("Warning syntax missing !, $syntax\n");
	}
	
	return 0;
}

sub get_commands($$)
{
	my $xml    = shift;
	my $plugin = shift;

	my $c = $xml->{command};
	my @tmpcmds = ();
	my %seen;

	return if ( not defined($c) );
	while (my ($key, $value) = each %{$c})
	{
		next if DetectInvalidConfig($key,$value,$c);
		
		my $name = lc($key); 
		$name =~ s/\!//g;
		my $alias;
		my $help = $value->{help}->{value};
		my $syntax = $value->{syntax}->{value};
		$syntax = '!' . $syntax if( $syntax !~ /^!.+?$/ );
		my $permission = get_permission($value->{permission}->{level});
		my $enabled = $value->{enabled}->{value};
		
		if ( $value->{alias} )
		{
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
		
		
		$plugin = "None" if ( $plugin eq "" || !defined($plugin));
		$alias = "None" if ( $alias eq "" || !defined($alias));
		if ( $enabled == 1 )
		{
			push(@tmpcmds, { name => $name, enabled => $enabled, syntax => $syntax, help => $help, permission => $permission, plugin => $plugin, alias => $alias });
			$command_count++
		}
		else
		{			
			push(@disabled_commands, { name => $name, enabled => $enabled, syntax => $syntax, help => $help, permission => $permission, plugin => $plugin, alias => $alias });
			$disabled_command_count++
		}
	}
	return @tmpcmds;	
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

sub WriteCommandsRef($$)
{
	my $file = shift;
	my $array = shift;
	my $msg = "";
	
	return unless( $file );
	if ( ref($array) ne 'ARRAY' )
	{
		$msg = "PrintCommandsHash Error Array Parameter Not an array Reference\n";
		PrintLog($msg);
		return;
	}

	foreach ( @$array )
	{
		my $name 		= $_->{name};
		my $syntax		= $_->{syntax};
		my $modlevel	= $_->{permission};
		my $plugin		= $_->{plugin};
		my $alias		= $_->{alias};
		my $help		= $_->{help};
		
		$msg = "Name: $name\nSyntax: $syntax\nHelp: $help\nPermission: $modlevel\nAlias: $alias\nPlugin: $plugin\n";
		$msg =~ s/Name: $name\n//g unless( $config_show_name );
		$msg =~ s/Permission: $modlevel\n//g unless( $config_show_modlevel );
		$msg =~ s/Plugin: $plugin\n//g unless( $config_show_plugin);
		$msg =~ s/Alias: $alias\n//g unless( $config_show_alias );
		$msg =~ s/Syntax: $syntax\n//g unless( $config_show_syntax );
		$msg =~ s/Help: $help\n//g unless( $config_show_help );
		$msg =~ s/Plugin: $plugin\n//g if ( $plugin eq "None" );
		$msg =~ s/Alias: $alias\n//g if ( $alias eq "None" );
		
		if ( $config_hidecommands == 1 )
		{
			if ( $syntax =~ /^(.+?)\s.+$/ ) {
				if ( $config_hidecommand_showmodlevel == 1 ) {
					WriteFile( $file, $1." = 1 ;$modlevel" );
				}
				else
				{
					WriteFile( $file, $1." = 1 " );
				}
			}
			else{
				PrintLog("Command $syntax syntax ERROR did not match command.\n");
			}
		}
		else
		{
			WriteFile($file, $msg);
		}
	}
}

sub PrintCommandsRef($)
{
	my $array = shift;
	my $msg = "";
	
	if ( ref($array) ne 'ARRAY' )
	{
		$msg = "PrintCommandsHash Error Array Parameter Not an array Reference\n";
		PrintLog($msg);
		return;
	}
	
	foreach ( @$array )
	{
		my $name 		= $_->{name};
		my $syntax		= $_->{syntax};
		my $modlevel	= $_->{permission};
		my $plugin		= $_->{plugin};
		my $alias		= $_->{alias};
		my $help		= $_->{help};
		
		$msg = "Name: $name\nSyntax: $syntax\nHelp: $help\nPermission: $modlevel\nAlias: $alias\nPlugin: $plugin\n";
		$msg =~ s/Name: $name\n//g unless( $config_show_name );
		$msg =~ s/Permission: $modlevel\n//g unless( $config_show_modlevel );
		$msg =~ s/Plugin: $plugin\n//g unless( $config_show_plugin);
		$msg =~ s/Alias: $alias\n//g unless( $config_show_alias );
		$msg =~ s/Syntax: $syntax\n//g unless( $config_show_syntax );
		$msg =~ s/Help: $help\n//g unless( $config_show_help );
		$msg =~ s/Plugin: $plugin\n//g if ( $plugin eq "None" );
		$msg =~ s/Alias: $alias\n//g if ( $alias eq "None" );
		
		PrintLog("$msg");
	}
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
			if (/^\s*Sort_Alphabetically\s*=\s*(\d+)/i)		 			{ $config_sort_alphabetically = $1; }
			if (/^\s*Sort_Permission\s*=\s*(\d+)/i)		 				{ $config_sort_modlevel = $1; }
			if (/^\s*Sort_Plugin\s*=\s*(\d+)/i)		 					{ $config_sort_plugin = $1; }
			if (/^\s*Sort_Reverse\s*=\s*(\d+)/i)		 				{ $config_sort_reverse = $1; }
			if (/^\s*UniqueCommands\s*=\s*(\d+)/i)						{ $config_unique = $1; }
			if (/^\s*Show_Alias\s*=\s*(\d+)/i)							{ $config_show_alias = $1; }
			if (/^\s*Show_Syntax\s*=\s*(\d+)/i)							{ $config_show_syntax = $1; }
			if (/^\s*Show_Name\s*=\s*(\d+)/i)							{ $config_show_name = $1; }
			if (/^\s*Show_Help\s*=\s*(\d+)/i)							{ $config_show_help = $1; }
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
