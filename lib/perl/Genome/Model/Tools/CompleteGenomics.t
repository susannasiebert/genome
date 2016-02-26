#!/usr/bin/env genome-perl

use strict;
use warnings;

BEGIN {
    $ENV{UR_DBI_NO_COMMIT} = 1;
    $ENV{UR_USE_DUMMY_AUTOGENERATED_IDS} = 1;
};

use above "Genome";
use Test::More;

if (Genome::Sys->arch_os ne 'x86_64') {
    plan skip_all => 'requires 64-bit machine';
}
else {
    plan tests => 3;
}

my $class = 'Genome::Model::Tools::CompleteGenomics';
use_ok($class);

my $cmd = $class->path_to_cgatools;
ok(-x $cmd, 'returned path to command');
ok($class->run_command('help'), 'can run cgatools');