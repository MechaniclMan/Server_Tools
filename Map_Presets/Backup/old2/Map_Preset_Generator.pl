package generate_map_presets;

# created by BigWrench

use File::Find;
use File::Basename;
use File::Spec::Functions qw(rel2abs);
use POSIX;
use File::Copy;
# use Cwd qw(cwd);

my $path = dirname(__FILE__);
my @files;
my $base_path					= "./";  # top level dir to search
our $configfile					= "./config.cfg";
our $config_preset_file 		= "./temp_objects.ddb";
our $config_ttini_enabled 		= 0;
our $config_ttini_file 			= "./temp_tt.ini";
our $config_mapini_enabled 		= 0;
our $config_mapini_file 		= "./temp_map.ini";


my @maps = ();
ReadConfig();
print "Path $path\n";

if ( -e "$configfile" )
{}
else
{
	print "configfile was not found. $configfile\n";
	return;
}

if ( -e "$config_preset_file" )
{}
else
{
	print "config_preset_file was not found. $config_preset_file\n";
	return;
}

if ( -e "$config_ttini_file" )
{}
else
{
	print "config_ttini_file was not found. $config_ttini_file\n";
	return;
}

mkdir('export' ) unless(-d 'export' );

foreach my $map (@maps) 
{
	chomp($map);
	my $dir = $path . "\\export\\";
	my $ddb = $dir . $map . ".ddb";
	my $ttini = $dir . $map . "_tt.ini";
	my $mapini = $dir . $map . "_map.ini";
	print "$ddb\n";
	copy("$config_preset_file", "$ddb" ) or die "Copy failed: $!";
	copy("$config_ttini_file", "$ttini" ) or die "Copy failed: $!" if ( $config_ttini_enabled == 1 );
	copy("$config_mapini_file", "$mapini" ) or die "Copy failed: $!" if ( $config_mapini_enabled == 1 );
	print "Generating $map Files.\n";
	
	#open ( PRESETFILE, '>>.\output.txt' );
	#print PRESETFILE "$map\n";
	#close PRESETFILE;	
}

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
			
			elsif ( $_ =~ m/^C\&C/ )
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