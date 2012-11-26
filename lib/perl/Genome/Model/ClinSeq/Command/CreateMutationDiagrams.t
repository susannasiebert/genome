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
use Test::More tests=>6; #One per 'ok', 'is', etc. statement below
use Genome::Model::ClinSeq::Command::CreateMutationDiagrams;
use Data::Dumper;

use_ok('Genome::Model::ClinSeq::Command::CreateMutationDiagrams') or die;

#Define the test where expected results are stored
my $expected_output_dir = $ENV{"GENOME_TEST_INPUTS"} . "/Genome-Model-ClinSeq-Command-CreateMutationDiagrams/2012-11-23/";
ok(-e $expected_output_dir, "Found test dir: $expected_output_dir") or die;

#Create a temp dir for results
my $temp_dir = Genome::Sys->create_temp_directory();
ok($temp_dir, "created temp directory: $temp_dir");

#Get a somatic variation build
my $somvar_build_id = 129973671;
my $somvar_build = Genome::Model::Build->get($somvar_build_id);

#Create create-mutation-diagrams command and execute
#genome model clin-seq create-mutation-diagrams --outdir=/tmp/create_mutation_diagrams/ --collapse-variants --max-transcripts=10 129973671
my $mutation_diagram_cmd = Genome::Model::ClinSeq::Command::CreateMutationDiagrams->create(outdir=>$temp_dir, collapse_variants=>1, max_transcripts=>10, builds=>[$somvar_build]);
$mutation_diagram_cmd->queue_status_messages(1);
my $r1 = $mutation_diagram_cmd->execute();
is($r1, 1, 'Testing for successful execution.  Expecting 1.  Got: '.$r1);

#Dump the output of update-analysis to a log file
my @output1 = $mutation_diagram_cmd->status_messages();
my $log_file = $temp_dir . "/CreateMutationDiagrams.log.txt";
my $log = IO::File->new(">$log_file");
$log->print(join("\n", @output1));
ok(-e $log_file, "Wrote message file from update-analysis to a log file: $log_file");

#The first time we run this we will need to save our initial result to diff against
#Genome::Sys->shellcmd(cmd => "cp -r -L $temp_dir/* $expected_output_dir");

#Perform a diff between the stored results and those generated by this test
my @diff = `diff -r $expected_output_dir -x '*.stderr' -x '*.stdout' $temp_dir`;
ok(@diff == 11, "Found only expected number of differences between expected results and test results")
or do { 
  diag("expected: $expected_output_dir\nactual: $temp_dir\n");
  diag("differences are:");
  diag(@diff);
  my $diff_line_count = scalar(@diff);
  print "\n\nFound $diff_line_count differing lines\n\n";
  Genome::Sys->shellcmd(cmd => "rm -fr /tmp/last-create-mutation-diagrams-result/");
  Genome::Sys->shellcmd(cmd => "mv $temp_dir /tmp/last-create-mutation-diagrams-result");
};

