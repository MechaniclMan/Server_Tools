my $zip = $PAR::LibCache{$ENV{PAR_PROGNAME}} || Archive::Zip->new(__FILE__);
my $member = eval { $zip->memberNamed('script/br_database_converter.pl') }
        or die qq(main.pl: Can't open perl script "script/br_database_converter.pl": No such file or directory ($zip));

# Remove everything but PAR hooks from @INC
my %keep = (
    \&PAR::find_par => 1,
    \&PAR::find_par_last => 1,
);
my $par_temp_dir = quotemeta( $ENV{PAR_TEMP} );
@INC =
    grep {
        exists($keep{$_})
        or $_ =~ /^$par_temp_dir/;
    }
    @INC;


PAR::_run_member($member, 1);

