#!/usr/bin/env genome-perl

BEGIN {
    $ENV{UR_USE_DUMMY_AUTOGENERATED_IDS} = 1;
    $ENV{UR_DBI_NO_COMMIT} = 1;
    #$ENV{UR_COMMAND_DUMP_STATUS_MESSAGES} = 1;
}

use strict;
use warnings;

use above "Genome";

use Test::More;

use_ok('Genome::InstrumentData::Command::CalculateReadCount') or die;

my $test_path1 = $ENV{GENOME_TEST_INPUTS} . '/Genome-InstrumentData-Command-CalculateReadCount';
test_with_path($test_path1);
my $test_path2 = $ENV{GENOME_TEST_INPUTS} . '/Genome-InstrumentData-Command-CalculateReadCount/with_flagstat';
test_with_path($test_path2);

done_testing();


#   This instrument_data has no genotype_file attribute
# should copy new one fine and make new genotype_file attribute
sub test_with_path {
    my ($test_path) = @_;

    my $instrument_data = Genome::InstrumentData::Solexa->create(); 
    ok($instrument_data, 'created dummy instrument data');

    my $bam_path = $test_path . "/input.bam";
    $instrument_data->bam_path($bam_path); 

    my $command = Genome::InstrumentData::Command::CalculateReadCount->create(instrument_data=>$instrument_data);
    ok($command->execute(), "execute returned true");

    my @read_count_attributes = $instrument_data->attributes(attribute_label => 'read_count');
    is(scalar (@read_count_attributes), 1, 'found exactly one attribute');
    my $read_count = $read_count_attributes[0]->attribute_value;
    ok(($read_count > 0), 'found finite read count');

    my $command2 = Genome::InstrumentData::Command::CalculateReadCount->create(instrument_data=>$instrument_data);
    ok($command2->execute(), "execute returned true a second time");
    is($command2->status_message, "Found existing read_count attribute was already defined.", 
            'shortcutted due to existing read_count attribute');

}
