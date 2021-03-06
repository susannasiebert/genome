#!/usr/bin/env genome-perl

use strict;
use warnings;

BEGIN {
    $ENV{UR_DBI_NO_COMMIT} = 1;
    $ENV{UR_USE_DUMMY_AUTOGENERATED_IDS} = 1;
}

use above 'Genome';
use Test::More;
use Genome::Model::SomaticVariation::Command::TestHelpers qw( create_test_objects run_test );

my $TEST_DATA_VERSION = 11;

my $pkg = 'Genome::Model::SomaticVariation::Command::CreateReport';
use_ok($pkg);
my $main_dir = Genome::Utility::Test->data_dir_ok($pkg, $TEST_DATA_VERSION);

my $input_dir = File::Spec->join($main_dir, "input");

my $somatic_variation_build = create_test_objects($main_dir);

my $output_exists = 0;

run_test(
    $pkg,
    $main_dir,
    $output_exists,
    somatic_variation_build => $somatic_variation_build,
    target_regions          => "$input_dir/target_regions.bed",
);

done_testing();
