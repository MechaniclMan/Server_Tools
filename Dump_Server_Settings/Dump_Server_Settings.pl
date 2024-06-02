package generate_map_presets;

use File::Copy;
use File::NCopy;
use Cwd qw(getcwd);

my @files = ();
my @maps = ();
our $configfile					= "./config.cfg";
our $config_preset_file 		= "./temp_objects.ddb";
our $config_ttini_enabled 		= 0;
our $config_ttini_file 			= "./temp_tt.ini";
our $config_mapini_enabled 		= 0;
our $config_mapini_file 		= "./temp_map.ini";
our $config_strings_enabled 	= 0;
our $config_strings_file 		= "./strings_map.tdb";
our $config_map_prefix 			= "C&C";
my $path = getcwd;
ReadConfig();

print "-------------------------\n";
print "Map Preset Generator v2.2\n";
print "-------------------------\n";

unless ( -e "$configfile" )
{
	print "config file was not found. $configfile\n";
	exit;
}

unless ( -e "$config_preset_file" )
{
	print "config_preset_file was not found. $config_preset_file\n";
	exit;
}

unless ( -e "$config_ttini_file" )
{
	print "config_ttini_file was not found. $config_ttini_file\n";
	exit;
}

mkdir('export' ) unless(-d 'export' );
mkdir("export\\presets") unless (-d "export\\presets");

foreach my $file (@maps) 
{
	chomp($map);
	my $mapname = $map;
	$mapname =~ s/c\&c_//i;
	my $dir = $path . "\\export\\";
	mkdir($dir . $mapname) unless (-d $mapname);
	$dir = $path . "\\export\\" . $mapname . "\\";
	my $dirconfig = $path . "\\" . $mapname . "\\";
	if ( -d $dirconfig )
	{
		#copy("$config_preset_file", "$ddb" ) or die "Copy failed: $ddb";
		mkdir('export\\' . $mapname ) unless(-d $dir );
		my $config_dir = File::NCopy->new(recursive => 1);
		$config_dir->copy($dirconfig, $dir); # Copy $dir1 to $dir2 recursively
		print "Copied Config $mapname Directory.\n";
	}
	my $ddbdir = $path . "\\export\\presets\\" . $map . ".ddb";
	my $ddb = $dir . $map . ".ddb";
	my $ttini = $dir . $map . "_tt.ini";
	my $mapini = $dir . $map . "_map.ini";
	my $strings  = $dir . "strings_map.tdb";
	copy("$config_preset_file", "$ddb" ) or die "Copy failed: $ddb";
	copy("$config_preset_file", "$ddbdir" ) or die "Copy failed: $ddbdir";
	copy("$config_ttini_file", "$ttini" ) or die "Copy failed: $ttini" if ( $config_ttini_enabled == 1 );
	copy("$config_mapini_file", "$mapini" ) or die "Copy failed: $mapini" if ( $config_mapini_enabled == 1 );
	copy("$config_strings_file", "$strings" ) or die "Copy failed: $strings" if ( $config_strings_enabled == 1 );
	print "Generating $map Files.\n";
	#print "$ddb\n";
}

print "Finished Generating Files.\n";
sleep(20);
exit(0);

sub ReadConfig
{
	my $fh;
	open ( $fh, $configfile ) or die "Config_File_Read: $!,";
	while ( <$fh> )
	{
		if ( $_ !~ m/^\#/ && $_ !~ m/^\s+$/ )		# If the line starts with a hash or is blank ignore it
		{
			if (/^\s*TEMPFILE\s*\=\s*(\S+)/i)							{ $config_preset_file = $1; }
			elsif (/^\s*TT_INI_ENABLED\s*\=\s*(\S+)/i)					{ $config_ttini_enabled = $1; }
			elsif (/^\s*TT_INI\s*\=\s*(\S+)/i)							{ $config_ttini_file = $1; }
			elsif (/^\s*MAP_INI_ENABLED\s*\=\s*(\S+)/i)					{ $config_mapini_enabled = $1; }
			elsif (/^\s*MAP_INI\s*\=\s*(\S+)/i)							{ $config_mapini_file = $1; }
			elsif (/^\s*STRINGS_ENABLED\s*\=\s*(\S+)/i)					{ $config_strings_enabled = $1; }
			elsif (/^\s*STRINGS_FILE\s*\=\s*(\S+)/i)					{ $config_strings_file = $1; }
			elsif (/^\s*MAP_PREFIX\s*\=\s*(\S+)/i)						{ $config_map_prefix = $1; }
			
			elsif ( $_ =~ m/^$config_map_prefix/ )
			{
				#print "Map $_\n";
				push @maps, $_;
			}
		}
	}

	my $config_error;
	$config_error .= "File " if (!$config_preset_file);
	if ($config_error)
	{
		print ( "[Config] ERROR: Missing config file option(s): $config_error" );
		sleep ( 10 );
		exit;
	}

	close $fh;
}
