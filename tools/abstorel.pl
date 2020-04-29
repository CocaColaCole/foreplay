#!/usr/bin/env perl
use warnings;

my $minx = 1000000;
my $miny = 1000000;

my $line = <STDIN>;

while ($line =~ m/\G,?\{(\d+),(\d+)\}/g) {
    my $x = $1;
    my $y = $2;
    if ($x < $minx) {
        $minx = $x;
    }
    if ($y < $miny) {
        $miny = $y
    }
}

undef pos $line;

while($line =~ m/\G,?\{(\d+),(\d+)\}/g) {
    my $x = $1;
    my $y = $2;
    printf "{%d,%d},", ($x - $minx), ($y - $miny);
}

print "\n $minx, $miny";
