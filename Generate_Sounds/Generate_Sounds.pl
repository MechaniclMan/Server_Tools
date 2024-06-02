package generate_sounds;

# generate_sounds used by jukebox and the sounds plugin.

use File::Find;
use File::Basename;
use File::Spec::Functions qw(rel2abs);
use MP3::Info;
use Audio::Wav;
use Fcntl;
#use POSIX qw/ceil/;
use POSIX;

#print "test \n";
#print dirname(rel2abs($0));

my $dirname = dirname(__FILE__);
my @files;
my $base_path					 = "./";  # top level dir to search
#print "$dirname.cfg\n";
our $config_sounds_dir 			= "./Sounds";
our $configfile					= "./generate_sounds.cfg";
our $config_sounds_file 		= "./sounds.list";
our $config_jukebox				= 0;

print "-------------------\n";
print "Generating Sounds\n";
print "-------------------\n";

ReadConfig();

mkdir('export' ) unless(-d 'export' );
mkdir($config_sounds_dir) unless (-d $config_sounds_dir);

if ( -e 'export' . $config_sounds_file )
{
	unlink 'export' . $config_sounds_file;
}

if ( -e "export/jukebox_xml.txt" )
{
	unlink "export/jukebox_xml.txt";
}

my @sounds = (); 
@sounds = process_files ($config_sounds_dir);

foreach(@sounds)
{
	my $dir = $_;
	my $file = basename($dir);
	
	my $time = 1;
	
	if ( $file =~ /^.+.wav$/ )
	{
		$time = wav_seconds($dir);
	}
	elsif ( $file =~ /^.+.mp3$/ )
	{
		$time = mp3_seconds($dir);
	}
	else
	{
		print "Error uknown sound file $file failed to get time\n";
		next;
	}
	
	if ( $config_jukebox )
	{
		open ( SOUNDSFILE, '>>.\export\jukebox_xml.txt' );
		print SOUNDSFILE "<cvar name=\"$file\" value=\"1\"/>\n";
		close SOUNDSFILE;
	}
	
	my @stat = stat $dir;
	my $size = (stat $dir)[7];
	
	my $format = "$file, $size, $time";
	
	print "$format\n";
	
	#my $fh;
	#open ( $fh, $config_sounds_file ) or die "Config_File_Read: $!,  $config_sounds_file";
	#print $fh "$format\n";
	#close $fh;
	
	
	open ( SOUNDSFILE, '>>.\export\jukebox.list' );
	print SOUNDSFILE "$format\n";
	close SOUNDSFILE;	
	
	#printf "$size $file length is %d:%d:%d %s\n", $info->{MM}, $info->{SS}, $info->{MS} ;
	
}

sub mp3_seconds
{
	my $dir = shift;
	my $info = get_mp3info($dir);
	my $length = $info->{SECS};
	print "Minutes $info->{MM} Secs $info->{SS}\n";
	$length = sprintf("%.2f", $length);
	my $rounded = ceil($length);
	$rounded = 1 if ( $rounded == 0 );
	return $rounded;
}

sub wav_seconds
{
	my $dir = shift;
	my $read = Audio::Wav -> read( $dir );
	my $audio_seconds = $read -> length_seconds();
	#return $audio_seconds;
	$audio_seconds = sprintf("%.2f", $audio_seconds);
	my $rounded = ceil($audio_seconds);
	$rounded = 1 if ( $rounded == 0 );
	return $rounded;
}


# Accepts one argument: the full path to a directory.
# Returns: A list of files that reside in that path.
sub process_files 
{
    my $path = shift;
    opendir (DIR, $path) or die "Unable to open $path: $!";

    my @files =
        #map { $path . '/' . $_ }
		map { $path . '/' . $_ }
        grep { !/^\.{1,2}$/ }
        readdir (DIR);
    closedir (DIR);

    # NOTE: we're returning the list of files
    return @files;
}

sub ReadConfig
{
	my $fh;
	open ( $fh, $configfile ) or die "Config_File_Read: $!,";
	while ( <$fh> )
	{
		if ( $_ !~ m/^\#/ && $_ !~ m/^\s+$/ )		# If the line starts with a hash or is blank ignore it
		{
			if (/^\s*Directory\s*\=\s*(\S+)/i)							{ $config_sounds_dir = $1; }
			if (/^\s*File\s*\=\s*(\S+)/i)								{ $config_sounds_file = $1; }
			if (/^\s*JukeBox\s*=\s*(\d+)/i)		 						{ $config_jukebox = $1; }
		}
	}

	my $config_error;
	$config_error .= "File " if (!$config_sounds_file);
	if ($config_error)
	{
		main::console_output ( "[Config] ERROR: Missing config file option(s): $config_error" );
		sleep ( 10 );
		exit;
	}

	close $fh;
}
