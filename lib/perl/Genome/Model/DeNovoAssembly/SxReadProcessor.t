#! /gsc/bin/perl

use strict;
use warnings;

use above 'Genome';

use Test::More;

use_ok('Genome::Model::DeNovoAssembly::SxReadProcessor') or die;

my $sample = Genome::Sample->create(name => '__TEST_SAMPLE__');
ok($sample, 'create test sample');
my $library = Genome::Library->create(name => '__TEST_LIBRARY__', sample => $sample);
ok($library, 'create library');
my @instrument_data;
my @inst_data_attrs = (
    {
        original_est_fragment_size => 250,
        is_paired_end => 1,
        read_count => 10000,
        read_length => 100,
    },
    {
        original_est_fragment_size => 3000,
        is_paired_end => 1,
        read_count => 10000,
        read_length => 100,
    },
    {
        original_est_fragment_size => 8000,
        is_paired_end => 1,
        read_count => 10000,
        read_length => 100,
    },
    {
        original_est_fragment_size => 100000,
        is_paired_end => 2,
        read_count => 10000,
        read_length => 777,
    },
);
my $i = 0;
for my $inst_data_attr ( @inst_data_attrs, ) {
    push @instrument_data, Genome::InstrumentData::Imported->create(
        library => $library,
        %$inst_data_attr,
    );
    $instrument_data[$i]->{sx_result_params} = {
        instrument_data_id => $instrument_data[$i]->id,
        output_file_count => ( $instrument_data[$i]->is_paired_end ? 2 : 1 ),
        output_file_type => 'sanger',
        test_name => ($ENV{GENOME_SOFTWARE_RESULT_TEST_NAME} || undef),
    };
    $i++;
}
is(@instrument_data, @inst_data_attrs, 'create inst data');

diag('SUCCESS (OLD WAY)');
my $processor = Genome::Model::DeNovoAssembly::SxReadProcessor->create(
    read_processor => 'trim default --param 1',
);
ok($processor, 'failed to create sx read processor');
is_deeply($processor->_default_read_processing, { condition => 'DEFAULT', processor => 'trim default --param 1', }, 'got default processing');
my $old_way_processing = { condition => 'DEFAULT', processor => 'trim default --param 1', };
for my $instrument_data ( @instrument_data ) {
    my $processing = $processor->determine_processing_for_instrument_data($instrument_data);
    is_deeply(
        $processing,
        $old_way_processing,
        'got correct processing for instrument data ',
    );
    my $sx_result_params = $processor->determine_sx_result_params_for_instrument_data($instrument_data),
    my %expected_sx_result_params = %{$instrument_data->{sx_result_params}};
    $expected_sx_result_params{read_processor} = $old_way_processing->{processor};
    is_deeply(
        $sx_result_params,
        \%expected_sx_result_params,
        'got correct sx result params for instrument data ',
    );
}

diag('SUCCESS (NEW WAY DEFAULT ONLY)');
$processor = Genome::Model::DeNovoAssembly::SxReadProcessor->create(
    read_processor => 'DEFAULT (trim default --param 1, coverage 10X)',
);
ok($processor, 'failed to create sx read processor');
is_deeply($processor->_default_read_processing, { condition => 'DEFAULT', processor => 'trim default --param 1', coverage => 10, }, 'got default processing');
my $new_way_processing = { condition => 'DEFAULT', processor => 'trim default --param 1', coverage => 10, };
for my $instrument_data ( @instrument_data ) {
    diag($instrument_data->id);
    my $processing = $processor->determine_processing_for_instrument_data($instrument_data);
    is_deeply(
        $processing,
        $new_way_processing,
        'got correct processing for instrument data ',
    );
    my $sx_result_params = $processor->determine_sx_result_params_for_instrument_data($instrument_data),
    my %expected_sx_result_params = %{$instrument_data->{sx_result_params}};
    $expected_sx_result_params{read_processor} = $new_way_processing->{processor};
    is_deeply(
        $sx_result_params,
        \%expected_sx_result_params,
        'got correct sx result params for instrument data ',
    );
}

diag('SUCESS (NEW WAY, FULL TEST)');
$processor = Genome::Model::DeNovoAssembly::SxReadProcessor->create(
    read_processor => 'DEFAULT (trim default --param 1) original_est_fragment_size <= 2.5 * read_length (DEFAULT, coverage 30X) original_est_fragment_size > 1000 and original_est_fragment_size <= 6000 (trim insert-size --min 1001 --max 6000 then filter by-length --length 50, coverage 20X) original_est_fragment_size > 6000 and original_est_fragment_size <= 10000 (trim insert-size --min 6001 --max 10000) read_length == 777 (filter --param 1 --qual 30)',
);
ok($processor, 'create sx read processor');
ok($processor->parser, 'got parser');
is_deeply($processor->_default_read_processing, { condition => 'DEFAULT', processor => 'trim default --param 1', }, 'got default processor');
my @expected_processings = (
    { condition => [qw/ original_est_fragment_size <= 2.5 * read_length /], processor => 'DEFAULT', coverage => 30, },
    { condition => [qw/ original_est_fragment_size > 1000 and original_est_fragment_size <= 6000 /], processor => 'trim insert-size --min 1001 --max 6000 then filter by-length --length 50', coverage => 20, },
    { condition => [qw/ original_est_fragment_size > 6000 and original_est_fragment_size <= 10000 /], processor => 'trim insert-size --min 6001 --max 10000', },
    { condition => [qw/ read_length == 777 /], processor => 'filter --param 1 --qual 30', },
);
is_deeply($processor->_read_processings, \@expected_processings, 'got read processors');
for ( my $i = 0; $i < @instrument_data; $i++ ) {
    my $instrument_data = $instrument_data[$i];
    diag($instrument_data->id);
    my $processing = $processor->determine_processing_for_instrument_data($instrument_data);
    is_deeply(
        $processing,
        $expected_processings[$i],
        'got correct processing for instrument data ',
    );
    my $sx_result_params = $processor->determine_sx_result_params_for_instrument_data($instrument_data),
    my %expected_sx_result_params = %{$instrument_data->{sx_result_params}};
    $expected_sx_result_params{read_processor} = $expected_processings[$i]->{processor};
    is_deeply(
        $sx_result_params,
        \%expected_sx_result_params,
        'got correct sx result params for instrument data ',
    );
}

diag('SUCCESS (MULTIPLE INST DATA)');
my $sx_result_params = $processor->determine_sx_result_params_for_multiple_instrument_data($instrument_data[1], $instrument_data[1]),
my %expected_sx_result_params = %{$instrument_data[1]->{sx_result_params}};
$expected_sx_result_params{read_processor} = $expected_processings[1]->{processor};
$expected_sx_result_params{instrument_data_id} = [ $instrument_data[1]->id, $instrument_data[1]->id, ];
is_deeply(
    $sx_result_params,
    \%expected_sx_result_params,
    'got correct sx result params for multiple instrument data ',
);

# FAILS
# mulitple inst data returns multiple processings
ok(!$processor->determine_sx_result_params_for_multiple_instrument_data(@instrument_data), 'failed to get processings for multiple inst data that did not match the same condition');

# no default
my $failed_processor = Genome::Model::DeNovoAssembly::SxReadProcessor->create(
    read_processor => 'DEFULT trim default --param 1',
);
ok(!$failed_processor, 'failed to create sx read processor');

# more than one default
$failed_processor = Genome::Model::DeNovoAssembly::SxReadProcessor->create(
    read_processor => 'DEFAULT (trim default --param 1) DEFAULT (trim default2 --param 1)',
);
ok(!$failed_processor, 'failed to create sx read processor');

done_testing();

