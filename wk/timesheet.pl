#!/usr/bin/env perl

############################################################################
###
### 日時ログを読み込み、TLセクションにある内容から、作業時間を割り出すスクリプト
###
### 使い方：
###   ./timesheet.pl
###   ./timesheet.pl 7
###   ./timesheet.pl 27
###   ./timesheet.pl 0527
###   ./timesheet.pl 20260527
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
use Encoding;
use FindBin qw($Bin);
use POSIX qw(strftime mktime);
use Time::Piece;
use lib "$Bin/lib";
use TLParse;

my $argv = shift @ARGV;
my $path = create_path($argv);

unless (-f $path) {
    print "ファイルが見つかりませんでした：\n";
    print Encode::decode('UTF-8', $path), "\n";

    die;
}

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

sub create_dir_path {
    my $base_path = "${Bin}/log";
    my $t = localtime;
    my $year = shift // $t->year;
    my $month = shift // $t->mon;
    my $day = shift // $t->mday;

    my $epoch_target_month_first_day = mktime(0, 0, 0, 1, $month - 1, $year - 1900);
    my $epoch_target_day = mktime(0, 0, 0, $day, $month - 1, $year - 1900);

    my $target_month_first_week = strftime('%W', localtime($epoch_target_month_first_day));
    my $target_day_week  = strftime('%W', localtime($epoch_target_day));
    my $week = $target_day_week - $target_month_first_week + 1;

    return sprintf("%s/%04d/%02d/w%d/%02d", $base_path, $year, $month, $week, $day);
}

sub create_path {
    my $param = shift;

    unless (defined $param) {
        my $path = create_dir_path(undef, undef, undef);
        return "${path}/log.md";
    }

    if ($param =~ /^(\d{1,2})$/) {
        my $path = create_dir_path(undef, undef, $1);
        return "${path}/log.md";
    } elsif ($param =~ /^(\d{2})(\d{2})$/) {
        my $path = create_dir_path(undef, $1, $2);
        return "${path}/log.md";
    } elsif ($param =~ /^(\d{4})(\d{2})(\d{2})$/) {
        my $path = create_dir_path($1, $2, $3);
        return "${path}/log.md";
    } else {
        return $param;
    }
}
