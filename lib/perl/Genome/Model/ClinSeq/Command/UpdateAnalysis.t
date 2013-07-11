#!/usr/bin/env genome-perl

#Written by Malachi Griffith

use strict;
use warnings;
use File::Basename;
use Cwd 'abs_path';

BEGIN {
    $ENV{UR_DBI_NO_COMMIT} = 1;
    $ENV{UR_USE_DUMMY_AUTOGENERATED_IDS} = 1;
    $ENV{NO_LSF} = 1;
};

use above "Genome";
use Test::More skip_all => "pending completion of 2892930879"; # tests=>12; #One per 'ok', 'is', etc. statement below
use Genome::Model::ClinSeq::Command::UpdateAnalysis;
use Data::Dumper;

use_ok('Genome::Model::ClinSeq::Command::UpdateAnalysis') or die;

#Define the test where expected results are stored
my $expected_output_dir = $ENV{"GENOME_TEST_INPUTS"} . "/Genome-Model-ClinSeq-Command-UpdateAnalysis/2013-07-11-b/";
ok(-e $expected_output_dir, "Found test dir: $expected_output_dir") or die;

#Create a temp dir for results
my $temp_dir = Genome::Sys->create_temp_directory();
ok($temp_dir, "created temp directory: $temp_dir");

#genome model clin-seq update-analysis  --individual='common_name=HG1'  --samples='id in [2874747197,2874769474,2875643613]'

#Get an individual - use HG1 as a test case
my $individual_id = 2874747196;
my $individual = Genome::Individual->get($individual_id);
ok($individual, "Obtained an individual from id: $individual_id");

#Obtain a normal DNA sample
my $normal_dna_sample_id = 2874769474;
my $normal_dna_sample = Genome::Sample->get($normal_dna_sample_id);
ok($normal_dna_sample, "Obtained a normal dna sample from id: $normal_dna_sample_id");

#Obtain a tumor DNA sample
my $tumor_dna_sample_id = 2874747197;
my $tumor_dna_sample = Genome::Sample->get($tumor_dna_sample_id);
ok($tumor_dna_sample, "Obtained a tumor dna sample from id: $tumor_dna_sample_id");

#Obtain a tumor RNA sample
my $tumor_rna_sample_id = 2875643613;
my $tumor_rna_sample = Genome::Sample->get($tumor_rna_sample_id);
ok($tumor_rna_sample, "Obtained a tumor rna sample from id: $tumor_rna_sample_id");

#Create the update-analysis command for step 1
my $update_analysis_cmd1 = Genome::Model::ClinSeq::Command::UpdateAnalysis->create(display_defaults=>1);
$update_analysis_cmd1->queue_status_messages(1);
my $r1 = $update_analysis_cmd1->execute();
is($r1, 1, 'Testing for successful execution of step 1.  Expecting 1.  Got: '.$r1);

#Create the update-analysis command for step 2
my $update_analysis_cmd2 = Genome::Model::ClinSeq::Command::UpdateAnalysis->create(individual=>$individual);
$update_analysis_cmd2->queue_status_messages(1);
my $r2 = $update_analysis_cmd2->execute();
is($r2, 1, 'Testing for successful execution of step 2.  Expecting 1.  Got: '.$r2);

#Create the update-analysis command for step 3
my $update_analysis_cmd3 = Genome::Model::ClinSeq::Command::UpdateAnalysis->create(individual=>$individual, samples=>[$normal_dna_sample,$tumor_dna_sample,$tumor_rna_sample]);
$update_analysis_cmd3->queue_status_messages(1);
my $r3 = $update_analysis_cmd3->execute();
is($r3, 1, 'Testing for successful execution of step 3.  Expecting 1.  Got: '.$r3);

#Dump the output of update-analysis to a log file
my @output1 = $update_analysis_cmd1->status_messages();
my @output2 = $update_analysis_cmd2->status_messages();
my @output3 = $update_analysis_cmd3->status_messages();
my $log_file = $temp_dir . "/UpdateAnalysis.log.txt";

my $log = IO::File->new(">$log_file");
$log->print(join("\n", @output1));
$log->print(join("\n", @output2));
$log->print(join("\n", @output3));
ok(-e $log_file, "Wrote message file from update-analysis to a log file: $log_file");

#The first time we run this we will need to save our initial result to diff against
#Genome::Sys->shellcmd(cmd => "cp -r -L $temp_dir/* $expected_output_dir");

#Perform a diff between the stored results and those generated by this test
my @diff = `diff -r $expected_output_dir $temp_dir`;
ok(@diff == 0, "No differences between expected results and test results")
or do { 
  diag("expected: $expected_output_dir\nactual: $temp_dir\n");
  diag("differences are:");
  diag(@diff);
  my $diff_line_count = scalar(@diff);
  print "\n\nFound $diff_line_count differing lines\n\n";
  Genome::Sys->shellcmd(cmd => "rm -fr /tmp/last-update-analysis-test-result");
  Genome::Sys->shellcmd(cmd => "mv $temp_dir /tmp/last-update-analysis-test-result");
};
