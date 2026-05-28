package TLParse;

use strict;
use warnings;
use utf8;
use Time::Local qw(timelocal);

# parse_file($path) -> arrayref of hashrefs
#   { begin => epoch, end => epoch_or_undef, name => str, description => str }
sub parse_file {
    my ($path) = @_;
    open my $fh, '<:encoding(UTF-8)', $path
        or die "tl-parse: cannot open $path: $!";
    my @lines = <$fh>;
    close $fh;
    chomp @lines;

    my ($year, $month, $day) = _extract_date(\@lines, $path);
    my @tl_lines = _extract_tl_section(\@lines);
    return _parse_entries(\@tl_lines, $year, $month, $day);
}

sub _extract_date {
    my ($lines, $path) = @_;
    for my $line (@$lines) {
        if ($line =~ /^#\s*(\d{4})年(\d{1,2})月(\d{1,2})日/) {
            return ($1, $2, $3);
        }
    }
    if ($path =~ m{log[\\/](\d{4})[\\/](\d{1,2})[\\/]w\d+[\\/](\d{1,2})[\\/]log\.md}) {
        return ($1, $2, $3);
    }
    die "tl-parse: cannot determine date for $path";
}

sub _extract_tl_section {
    my ($lines) = @_;
    my @out;
    my $in = 0;
    for my $line (@$lines) {
        if ($line =~ /^##\s+TL\s*$/) {
            $in = 1;
            next;
        }
        if ($in && $line =~ /^##\s+/) {
            last;
        }
        push @out, $line if $in;
    }
    return @out;
}

sub _parse_entries {
    my ($lines, $year, $month, $day) = @_;
    my @entries;
    my $cur;
    my @desc;
    my $name_set = 0;

    my $flush = sub {
        return unless defined $cur;
        $cur->{description} = join("\n", @desc);
        push @entries, $cur;
        $cur = undef;
        @desc = ();
        $name_set = 0;
    };

    for my $line (@$lines) {
        if ($line =~ /^-\s+(\d{4})-(\d{4})?\s*$/) {
            $flush->();
            my ($s, $e) = ($1, $2);
            $cur = {
                begin       => _to_epoch($year, $month, $day, $s),
                end         => (defined $e ? _to_epoch($year, $month, $day, $e) : undef),
                name        => undef,
                description => '',
            };
            next;
        }
        next unless defined $cur;
        if (!$name_set && $line =~ /^\s+-\s+(.*)$/) {
            $cur->{name} = $1;
            $name_set = 1;
            next;
        }
        if ($line =~ /^\s+\S/) {
            push @desc, $line;
            next;
        }
    }
    $flush->();
    return \@entries;
}

sub _to_epoch {
    my ($y, $mo, $d, $hhmm) = @_;
    my ($h, $m) = ($hhmm =~ /^(\d{2})(\d{2})$/);
    return timelocal(0, $m + 0, $h + 0, $d + 0, $mo - 1, $y + 0);
}

1;
