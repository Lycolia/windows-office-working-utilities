#!/usr/bin/env perl

############################################################################
###
### 日時ログを読み込み、TLセクションにある内容から、作業時間を割り出すスクリプト
###
### 使い方：
###   ./timesheet.pl log/2026/05/w5/27/log.md
###
### 入出力例：
### 入力：
### ```markdown
### ## TL
###
### - 1000-1030
###   - ほげ
### - 1100-1300
###   - ふが
###     - ふがふが
### - 1300-1430
###   - ぴよ
### ```
### 出力：
### ```
### ほげ	0.5
### ふが	2
### ぴよ	1.5
### ```
############################################################################

use strict;
use warnings;
use utf8;
use open qw(:std :encoding(UTF-8));
use FindBin qw($Bin);
use lib "$Bin/lib";
use TLParse;

my $path = shift @ARGV
    or die "usage: $0 <log.md>\n";

my $entries = TLParse::parse_file($path);

my %hours;
my @order;
for my $e (@$entries) {
    next unless defined $e->{end};
    my $name = $e->{name};
    my $h = ($e->{end} - $e->{begin}) / 3600;
    push @order, $name unless exists $hours{$name};
    $hours{$name} += $h;
}

for my $name (@order) {
    printf "%s\t%g\n", $name, $hours{$name};
}
