use strict;
use lib '../lib';
use Test::More;
use Test::Deep;
#use 5.010;
use Config::JSON;
$|=1;

# This is first go at a script to check for more issues that Missions.t does.
# it is currently based on Missions.t is very ugly
# at some point it should check things based on a table or a JSON data file
# currently it only checks a very few things

# the ship numbers will probably need to be tweaked as time passes
# and we have a better idea what we want in missions


my $resources = Config::JSON->new('../var/resources.conf');
my $buildings = $resources->get('buildings');

my $names = Config::JSON->new('../var/names.conf');
my $r_name = $names->get('resources');

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
    ok($config->get('max_university_level') > 1, $filename.' max university level > 1');
    ok($config->get('max_university_level') <= 30, $filename.' max university level <= 30');
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
    }

    #Resource names
    my $obre = $config->get('mission_objective')->{resources};
    my $obre_valid;
    $obre_valid = 1 if( ! defined $obre or ref $obre eq 'HASH' );
    ok( defined $obre_valid, $filename.' uses resources hash');
    #ok( ! defined $obre or ref $obre eq 'HASH', $filename.' uses resources hash');
    #ok( ! defined $obre or ref $obre eq 'HASH', $filename.' uses resources hash');
    #ok( ref $obre eq 'HASH', $filename.' has resources hash');
    #ok( ! defined $obre , $filename.' defined resources hash');
    if ( ref $obre eq 'HASH' ){
        for my $key ( keys %$obre ) {
            ok( exists $r_name->{$key}, $filename.' has resouces names')
                or diag( "Bad resource name '$key'." );
        }
    }

    # Objective ships sanity
    my $obships = $config->get('mission_objective')->{ships};
    for my $ship ( @$obships ) {
        ok ( ( $ship->{speed} < 25000 ),
            $filename.' sane speed on ships' );
        ok ( ( $ship->{combat} == 0 or $ship->{combat} > 199 ),
            $filename.' sane combat on ships' );
        ok( ($ship->{type} ne 'cargo_ship' or $ship->{speed} < 5001 ),
            $filename.' requires a very fast ship' );
        ok( ! ($ship->{type} eq 'probe' and $ship->{combat} > 0 ),
            $filename.' requires a probe with combat' );
    }
    # Reward ships sanity
    my $reships = $config->get('mission_reward')->{ships};
    for my $ship ( @$reships ) {
        ok ( ( $ship->{speed} < 25000 ),
            $filename.' sane speed on ships' );
        ok ( ( $ship->{combat} == 0 or $ship->{combat} > 199 ),
            $filename.' sane combat on ships' );
        ok( ($ship->{type} ne 'cargo_ship' or $ship->{speed} < 5001 ),
            $filename.' gives a very fast ship' );
        ok( ! ($ship->{type} eq 'probe' and $ship->{combat} > 0 ),
            $filename.' gives a probe with combat' );
    }

}

done_testing();



