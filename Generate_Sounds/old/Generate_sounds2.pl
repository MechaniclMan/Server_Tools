package generate_sounds;

use File::Find;

my @files;
my $start_dir = "X:\BrenBot_154\Br_Plugins\Sounds\ServerSounds";  # top level dir to search

print "start\n";

find();

sub find(
    sub { push @files, $File::Find::name unless -d; }, 
    $start_dir
);


for my $file (@files) {
    print "$file\n";
}

process_files ($base_path);

# Accepts one argument: the full path to a directory.
# Returns: A list of files that reside in that path.
sub process_files {
    my $path = shift;

    opendir (DIR, $path)
        or die "Unable to open $path: $!";

    # We are just chaining the grep and map from
    # the previous example.
    # You'll see this often, so pay attention ;)
    # This is the same as:
    # LIST = map(EXP, grep(EXP, readdir()))
    my @files =
        # Third: Prepend the full path
        map { $path . '/' . $_ }
        # Second: take out '.' and '..'
        grep { !/^\.{1,2}$/ }
        # First: get all files
        readdir (DIR);

    closedir (DIR);

    for (@files) {
        if (-d $_) {
            # Add all of the new files from this directory
            # (and its subdirectories, and so on... if any)
            push @files, process_files ($_);

        } else {
            # Do whatever you want here =) .. if anything.
        }
    }
    # NOTE: we're returning the list of files
    return @files;
}