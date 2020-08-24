package generate_sounds;

use File::Find;
use File::Basename;
use MP3::Info;
use Audio::Wav;
use Fcntl;

my @files;
my $base_path = "X:/Users/Blackstar/Desktop/RxD_Contain/StringsSoundMod/cnc95/";  # top level dir to search

print "start\n";


if ( -e "sounds.list" )
{
	unlink "sounds.list";
}

my @sounds = ();
@sounds = process_files ($base_path);

foreach(@sounds)
{
	my $dir = $_;
	my $file = basename($dir);
	
	my $length = 0;
	
	if ( $file =~ /^.+.wav$/ )
	{
		$length = wavlength($dir);
	}
	elsif ( $file =~ /^.+.mp3$/ )
	{
		my $info = get_mp3info($dir);
		$length = $info->{SS};
		$length = sprintf("%.2f", $length);
	}
	else
	{
		print "Error uknown sound file failed to get length\n";
	}
	
	my @stat = stat $dir;
	my $size = (stat $dir)[7];
	
	my $format = "\"$size\", \"$file\", \"$length\"";
	
	print "$format\n";
	
	open ( SOUNDSFILE, '>>.\sounds.list' );
	print SOUNDSFILE "$format\n";
	close SOUNDSFILE;
	
	
	#printf "$size $file length is %d:%d:%d %s\n", $info->{MM}, $info->{SS}, $info->{MS} ;
	
}

sub wavlength
{
	my $dir = shift;
	my $read = Audio::Wav -> read( $dir );
	my $audio_seconds = $read -> length_seconds();
	my $rounded = sprintf("%.2f", $audio_seconds);
	return $rounded;
}


# Accepts one argument: the full path to a directory.
# Returns: A list of files that reside in that path.
sub process_files 
{
    my $path = shift;
    opendir (DIR, $path) or die "Unable to open $path: $!";

    my @files =
        map { $path . '/' . $_ }
        grep { !/^\.{1,2}$/ }
        readdir (DIR);
    closedir (DIR);

    for (@files) 
	{
        if (-d $_) 
		{
            #push @files, process_files ($_);
			#print "DIRECTORY $_\n";
        } 
		else {
            #print "$_\n";
        }
    }
    # NOTE: we're returning the list of files
    return @files;
}