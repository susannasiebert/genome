#!/usr/bin/env genome-perl

use strict;
use warnings;

BEGIN {
    $ENV{UR_DBI_NO_COMMIT} = 1;
    $ENV{UR_USE_DUMMY_AUTOGENERATED_IDS} = 1; #FeatureLists generate their own IDs, but this is still a good idea
};

use Test::More tests => 9;

use above 'Genome';
use Genome::Utility::Test qw(command_execute_fail_ok);

use_ok('Genome::FeatureList');

my $test_bed_file = __FILE__ . '.bed';
ok(-e $test_bed_file, 'test file ' . $test_bed_file . ' exists');

my $test_bed_file_md5 = Genome::Sys->md5sum($test_bed_file);

my $feature_list;
{
    local $ENV{UR_COMMAND_DUMP_STATUS_MESSAGES} = 0;
    $feature_list = Genome::FeatureList->create(
        name                => 'GFL test feature-list',
        format              => 'true-BED',
        content_type        => 'target region set',
        file_path           => $test_bed_file,
        file_content_hash   => $test_bed_file_md5,
    );
}

ok($feature_list, 'created a feature list');
isa_ok($feature_list, 'Genome::FeatureList');

eval {
    my $change_format_cmd = Genome::FeatureList::Command::ChangeFormat->create(
        feature_list => $feature_list,
        format              => '1-based',
    );
    command_execute_fail_ok($change_format_cmd,
        {
        error_messages => [q(feature-list GFL test feature-list does not have format set to 'unknown')],
        },
        'execute Genome::FeatureList::Command::ChangeFormat');
};

ok($feature_list->format ne 'unknown', 'failed to change format when format != "unknown"');


my $feature_list_2;
{
    local $ENV{UR_COMMAND_DUMP_STATUS_MESSAGES} = 0;
    $feature_list_2 = Genome::FeatureList->create(
        name                => 'GFL test feature-list',
        format              => 'unknown',
        content_type        => 'target region set',
        file_path           => $test_bed_file,
        file_content_hash   => $test_bed_file_md5,
    );
}

ok($feature_list_2, 'created another feature list');
isa_ok($feature_list_2, 'Genome::FeatureList');

my $fail_change_format_2; 
eval {
    $fail_change_format_2 = Genome::FeatureList::Command::ChangeFormat->execute(
        feature_list => $feature_list_2,
        format              => '1-based',
    );
};

ok($feature_list_2->format eq '1-based', 'successfully changed format when format == "unknown"');
