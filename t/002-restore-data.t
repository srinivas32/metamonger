#!/usr/bin/perl

use strict;
use warnings;

use JSON;
use Shell::Command;

use Test::Most;

use Data::Dumper;

system ("mkdir -p 't/etc/'");

die $? if $?;

chdir 't/etc/' or die $!;

my $STORAGE = '.metamonger';

open (FILE, ">$STORAGE") or die $?;
print FILE '{"config":{"program":"metamonger","storage_version":0,"strict_json":1,"tracked_metadata":{"atime":1,"gid":0,"mode":2,"mtime":1,"uid":0}}}';
close FILE;

if (!-e 'metamonger') {
    system ("ln -s '../../metamonger'");
    die $? if $?;
}

eval {
    touch '001';
    touch '002';
    touch '003';
};
die $@ if $@;

utime 1337, 42, '001';

utime -1, 9001, '002';
utime 9002, -1, '003';

system ('./metamonger --save 001 002 003');
die $? if $?;

eval {
    touch '001';
    touch '002';
    touch '003';
};
die $@ if $@;

system ('./metamonger --restore');

my (undef,                          # device number
 undef,                          # inode number
 undef,
 undef,                          # number of (hard) links
 undef,
 undef,
 undef,                          # device identifier
 undef,                          # total size
 $atime_1,
 $mtime_1,
 undef,                          # ctime; can not be set on Unix
 undef,                          # preferred block size
 undef,                          # blocks allocated
) = lstat('001') or log_fatal {"Could not stat '001': $!"};

ok $atime_1 == 1337;
ok $mtime_1 == 42;

my (undef,                          # device number
 undef,                          # inode number
 undef,
 undef,                          # number of (hard) links
 undef,
 undef,
 undef,                          # device identifier
 undef,                          # total size
 undef,
 $mtime_2,
 undef,                          # ctime; can not be set on Unix
 undef,                          # preferred block size
 undef,                          # blocks allocated
) = lstat('002') or log_fatal {"Could not stat '002': $!"};

ok $mtime_2 == 9001;

my (undef,                          # device number
 undef,                          # inode number
 undef,
 undef,                          # number of (hard) links
 undef,
 undef,
 undef,                          # device identifier
 undef,                          # total size
 $atime_3,
 undef,
 undef,                          # ctime; can not be set on Unix
 undef,                          # preferred block size
 undef,                          # blocks allocated
) = lstat('003') or log_fatal {"Could not stat '003': $!"};

ok $atime_3 = 9002;

rm_rf '../etc';

done_testing;
