use strict;
use lib '../lib';
use Test::More;
use Test::Deep;
#use 5.010;
use Config::JSON;
$|=1;


my $resources = Config::JSON->new('../var/resources.conf');
my $buildings = $resources->get('buildings');

opendir my $folder, '../missions';
my @files = readdir $folder;
closedir $folder;

my $config;
foreach my $filename (@files) {
    next if $filename =~ m/^\./;
    ok($filename =~ m/^[a-z0-9\-\_]+\.((mission)|(part\d+))$/i, $filename.' is valid filename');
    eval{ $config = Config::JSON->new('../missions/'.$filename)};
    isa_ok($config,'Config::JSON');
    ok($config->get('max_university_level'), $filename.' has max university level');
    my $ends_well = qr/(\?|\!|\.)$/;
    like($config->get('network_19_headline'), $ends_well, $filename.' headline has punctuation');
    like($config->get('network_19_completion'), $ends_well, $filename.' completion has punctuation');
    my @plans;
    my $temp = $config->get('mission_objective')->{plans};
    push @plans, @{$temp} if (ref $temp eq 'ARRAY');
    $temp = $config->get('mission_reward')->{plans};
    push @plans, @{$temp} if (ref $temp eq 'ARRAY');
    foreach my $plan (@plans) {
        my $class = $plan->{classname};
        ok(exists $buildings->{$class}, $filename.' plan class '.$class.' exists');
        unless (defined $plan->{quantity}) {
            diag($filename.' plan class '.$class.' does not have quantity.');
        }
    }
    my @glyphs;
    $temp = $config->get('mission_objective')->{glyphs};
    push @glyphs, @{$temp} if (ref $temp eq 'ARRAY');
    $temp = $config->get('mission_reward')->{glyphs};
    push @glyphs, @{$temp} if (ref $temp eq 'ARRAY');
    foreach my $glyph (@glyphs) {
        unless (defined $glyph->{quantity}) {
            diag($filename.' glyph type '.$glyph->{type}.' does not have quantity.');
        }
    }
    my @ships;
    $temp = $config->get('mission_reward')->{ships};
    push @ships, @{$temp} if (ref $temp eq 'ARRAY');
    foreach my $ship (@ships) {
        my $name = $ship->{name};
        $name =~ s/[^\w\d\s]//g;
        ok( ($name eq $ship->{name} and $name ne ''), $filename.' ship name in reward has puncuation or is zero length.');
        unless (defined $ship->{quantity}) {
            diag($filename.' ship type '.$ship->{type}.' does not have quantity.');
        }
    }
    undef @ships;
    $temp = $config->get('mission_objective')->{ships};
    push @ships, @{$temp} if (ref $temp eq 'ARRAY');
    foreach my $ship (@ships) {
        unless (defined $ship->{quantity}) {
            diag($filename.' ship type '.$ship->{type}.' does not have quantity.');
        }
    }
}

done_testing();



