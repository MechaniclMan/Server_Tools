
use Data::Dumper;
use strict;
use vars qw($list);
eval "require 'config_file'";

my %dispatch;
# these hash-keys all have another hash-ref as value
dispatch{ qw/key1 key2 key3 key5 key6 key6/ } =
(sub {
my ($key, $val, $hash) = $_;
die "Duplicate key '$key'\n" if exists $hash->{ $key };
if ($val > 1) {
for (my $i = 0; $i <= $#$val; $i += 2) {
die "Duplicate key '$val->[$i]'\n"
if exists $hash->{ $key }->{ $val->[$i] };
if (! ref $val->[$i+1]) {
$hash->{ $key }->{ $val->[$i] } = $val->[$i+1];
} else {
$dispatch{$val->[$i]}->($val->[$i], $val->[$i+1], $hash);
}
}
} else {
$hash->{ $key } = $val;
}
}) x 6;
# takes an array-ref as value
$dispatch{ key4 } =
sub {
my ($key, $val, $hash) = $_;
if (exists $hash->{ $key }) {
die "Duplicate key '$key'\n";
}
$hash->{ $key } = $val;
};

my %hash;
for (my $i = 0; $i <= $#$list; $i += 2) {
$dispatch{$list->[$i]}->($list->[$i], $list->[$i+1], \%hash);
}
print Dumper \%hash;


1;