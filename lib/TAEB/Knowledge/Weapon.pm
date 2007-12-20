#!/usr/bin/env perl
package TAEB::Knowledge::Weapon;
use Moose;

has weaponlist => (
    is      => 'ro',
    isa     => 'HashRef',
    default => sub {
        my $weapons = {
            'aklys' => {
              sdam  => 'd6',
              ldam  => 'd3',
              tohit => '0',
              type  => 'iron',
            },
            'arrow' => {
              sdam  => 'd6',
              ldam  => 'd6',
              tohit => '0',
              type  => 'iron',
            },
            'athame' => {
              sdam  => 'd4',
              ldam  => 'd3',
              tohit => '2',
              type  => 'iron',
            },
            'axe' => {
              sdam  => 'd6',
              ldam  => 'd4',
              tohit => '0',
              type  => 'iron',
            },
            'bardiche' => {
              sdam  => '2d4',
              ldam  => '3d4',
              tohit => '0',
              type  => 'iron',
            },
            'bare-handed combat' => {
              sdam  => 'd2',
              ldam  => 'd2',
              tohit => '0',
              type  => 'none',
            },
            'battle-axe' => {
              sdam  => 'd8+d4',
              ldam  => 'd6+2d4',
              tohit => '0',
              type  => 'iron',
            },
            'bec-de-corbin' => {
              sdam  => 'd8',
              ldam  => 'd6',
              tohit => '0',
              type  => 'iron',
            },
            'bill-guisarme' => {
              sdam  => '2d4',
              ldam  => 'd10',
              tohit => '0',
              type  => 'iron',
            },
            'boomerang' => {
              sdam  => 'd9',
              ldam  => 'd9',
              tohit => '0',
              type  => 'wood',
            },
            'bow' => {
              sdam  => 'd2',
              ldam  => 'd2',
              tohit => '0',
              type  => 'wood',
            },
            'broadsword' => {
              sdam  => '2d4',
              ldam  => 'd6+1',
              tohit => '0',
              type  => 'iron',
            },
            'bullwhip' => {
              sdam  => 'd2',
              ldam  => '1',
              tohit => '0',
              type  => 'leather',
            },
            'Cleaver' => {
              sdam  => 'd8+d6+d4',
              ldam  => '2d6+2d4',
              tohit => 'd3',
              type  => 'iron',
            },
            'club' => {
              sdam  => 'd6',
              ldam  => 'd3',
              tohit => '0',
              type  => 'wood',
            },
            'crossbow bolt' => {
              sdam  => 'd4+1',
              ldam  => 'd6+1',
              tohit => '0',
              type  => 'iron',
            },
            'crossbow' => {
              sdam  => 'd2',
              ldam  => 'd2',
              tohit => '0',
              type  => 'wood',
            },
            'crysknife' => {
              sdam  => 'd10',
              ldam  => 'd10',
              tohit => '3',
              type  => 'mineral',
            },
            'Demonbane' => {
              sdam  => 'd8',
              ldam  => 'd12',
              tohit => 'd5',
              type  => 'iron',
            },
            'dagger' => {
              sdam  => 'd4',
              ldam  => 'd3',
              tohit => '2',
              type  => 'iron',
            },
            'dart' => {
              sdam  => 'd3',
              ldam  => 'd2',
              tohit => '0',
              type  => 'iron',
            },
            'Dragonbane' => {
              sdam  => '2d4',
              ldam  => 'd6+1',
              tohit => 'd5',
              type  => 'iron',
            },
            'dwarvish mattock' => {
              sdam  => 'd12',
              ldam  => 'd8+2d6',
              tohit => '-1',
              type  => 'iron',
            },
            'dwarvish short sword' => {
              sdam  => 'd7',
              ldam  => 'd8',
              tohit => '0',
              type  => 'iron',
            },
            'dwarvish spear' => {
              sdam  => 'd8',
              ldam  => 'd8',
              tohit => '0',
              type  => 'iron',
            },
            'elven arrow' => {
              sdam  => 'd7',
              ldam  => 'd6',
              tohit => '0',
              type  => 'wood',
            },
            'elven bow' => {
              sdam  => 'd2',
              ldam  => 'd2',
              tohit => '0',
              type  => 'wood',
            },
            'elven broadsword' => {
              sdam  => 'd6+d4',
              ldam  => 'd6+1',
              tohit => '0',
              type  => 'wood',
            },
            'elven dagger' => {
              sdam  => 'd5',
              ldam  => 'd3',
              tohit => '2',
              type  => 'wood',
            },
            'elven short sword' => {
              sdam  => 'd8',
              ldam  => 'd8',
              tohit => '0',
              type  => 'wood',
            },
            'elven spear' => {
              sdam  => 'd7',
              ldam  => 'd8',
              tohit => '0',
              type  => 'wood',
            },
            'Excalibur' => {
              sdam  => 'd8+d10',
              ldam  => 'd12+d10',
              tohit => 'd5',
              type  => 'iron',
            },
            'fauchard' => {
              sdam  => 'd6',
              ldam  => 'd8',
              tohit => '0',
              type  => 'iron',
            },
            'Fire Brand' => {
              sdam  => 'd8',
              ldam  => 'd12',
              tohit => 'd5',
              type  => 'iron',
            },
            'flail' => {
              sdam  => 'd6+1',
              ldam  => '2d4',
              tohit => '0',
              type  => 'iron',
            },
            'flintstone' => {
              sdam  => 'd6',
              ldam  => 'd6',
              tohit => '0',
              type  => 'mineral',
            },
            'Frost Brand' => {
              sdam  => 'd8',
              ldam  => 'd12',
              tohit => 'd5',
              type  => 'iron',
            },
            'Giantslayer' => {
              sdam  => 'd8',
              ldam  => 'd12',
              tohit => 'd5',
              type  => 'iron',
            },
            'glaive' => {
              sdam  => 'd6',
              ldam  => 'd10',
              tohit => '0',
              type  => 'iron',
            },
            'grappling hook' => {
              sdam  => 'd2',
              ldam  => 'd6',
              tohit => '0',
              type  => 'iron',
            },
            'Grayswandir' => {
              sdam  => 'd8',
              ldam  => 'd8',
              tohit => 'd5',
              type  => 'silver',
            },
            'Grimtooth' => {
              sdam  => 'd6+d3',
              ldam  => 'd6+d3',
              tohit => 'd2+2',
              type  => 'iron',
            },
            'guisarme' => {
              sdam  => '2d4',
              ldam  => 'd8',
              tohit => '0',
              type  => 'iron',
            },
            'halberd' => {
              sdam  => 'd10',
              ldam  => '2d6',
              tohit => '0',
              type  => 'iron',
            },
            'javelin' => {
              sdam  => 'd6',
              ldam  => 'd6',
              tohit => '0',
              type  => 'iron',
            },
            'katana' => {
              sdam  => 'd10',
              ldam  => 'd12',
              tohit => '1',
              type  => 'iron',
            },
            'knife' => {
              sdam  => 'd3',
              ldam  => 'd2',
              tohit => '0',
              type  => 'iron',
            },
            'lance' => {
              sdam  => 'd6',
              ldam  => 'd8',
              tohit => '0',
              type  => 'iron',
            },
            'long sword' => {
              sdam  => 'd8',
              ldam  => 'd12',
              tohit => '0',
              type  => 'iron',
            },
            'Longbow of Diana' => {
              sdam  => 'd2',
              ldam  => 'd2',
              tohit => 'd5',
              type  => 'wood',
            },
            'lucern hammer' => {
              sdam  => '2d4',
              ldam  => 'd6',
              tohit => '0',
              type  => 'iron',
            },
            'mace' => {
              sdam  => 'd6+1',
              ldam  => 'd6',
              tohit => '0',
              type  => 'iron',
            },
            'Magicbane' => {
              sdam  => '2d4',
              ldam  => 'd4+d3',
              tohit => 'd5+2',
              type  => 'iron',
            },
            'martial arts' => {
              sdam  => 'd4',
              ldam  => 'd4',
              tohit => '0',
              type  => 'none',
            },
            'Mjollnir' => {
              sdam  => 'd4+1',
              ldam  => 'd4',
              tohit => 'd5',
              type  => 'iron',
            },
            'morning star' => {
              sdam  => '2d4',
              ldam  => 'd6+1',
              tohit => '0',
              type  => 'iron',
            },
            'Ogresmasher' => {
              sdam  => 'd4+1',
              ldam  => 'd4',
              tohit => 'd5',
              type  => 'iron',
            },
            'orcish arrow' => {
              sdam  => 'd5',
              ldam  => 'd6',
              tohit => '0',
              type  => 'iron',
            },
            'orcish bow' => {
              sdam  => 'd2',
              ldam  => 'd2',
              tohit => '0',
              type  => 'wood',
            },
            'orcish dagger' => {
              sdam  => 'd3',
              ldam  => 'd3',
              tohit => '2',
              type  => 'iron',
            },
            'orcish short sword' => {
              sdam  => 'd5',
              ldam  => 'd8',
              tohit => '0',
              type  => 'iron',
            },
            'orcish spear' => {
              sdam  => 'd5',
              ldam  => 'd8',
              tohit => '0',
              type  => 'iron',
            },
            'Orcrist' => {
              sdam  => 'd6+d4',
              ldam  => 'd6+1',
              tohit => 'd5',
              type  => 'wood',
            },
            'rocks/gems/glass' => {
              sdam  => 'd3',
              ldam  => 'd3',
              tohit => '0',
              type  => 'vary',
            },
            'partisan' => {
              sdam  => 'd6',
              ldam  => 'd6+1',
              tohit => '0',
              type  => 'iron',
            },
            'pick-axe' => {
              sdam  => 'd6',
              ldam  => 'd3',
              tohit => '0',
              type  => 'iron',
            },
            'quarterstaff' => {
              sdam  => 'd6',
              ldam  => 'd6',
              tohit => '0',
              type  => 'wood',
            },
            'ranseur' => {
              sdam  => '2d4',
              ldam  => '2d4',
              tohit => '0',
              type  => 'iron',
            },
            'rubber hose' => {
              sdam  => 'd4',
              ldam  => 'd3',
              tohit => '0',
              type  => 'plastic',
            },
            'runesword' => {
              sdam  => '2d4',
              ldam  => 'd6+1',
              tohit => '0',
              type  => 'iron',
            },
            'scalpel' => {
              sdam  => 'd3',
              ldam  => 'd3',
              tohit => '2',
              type  => 'metal',
            },
            'Sceptre of Might' => {
              sdam  => 'd6+1',
              ldam  => 'd6',
              tohit => 'd5',
              type  => 'iron',
            },
            'scimitar' => {
              sdam  => 'd8',
              ldam  => 'd8',
              tohit => '0',
              type  => 'iron',
            },
            'short sword' => {
              sdam  => 'd6',
              ldam  => 'd8',
              tohit => '0',
              type  => 'iron',
            },
            'shuriken' => {
              sdam  => 'd8',
              ldam  => 'd6',
              tohit => '2',
              type  => 'iron',
            },
            'silver arrow' => {
              sdam  => 'd6',
              ldam  => 'd6',
              tohit => '0',
              type  => 'silver',
            },
            'silver dagger' => {
              sdam  => 'd4',
              ldam  => 'd3',
              tohit => '2',
              type  => 'silver',
            },
            'silver saber' => {
              sdam  => 'd8',
              ldam  => 'd8',
              tohit => '0',
              type  => 'silver',
            },
            'silver spear' => {
              sdam  => 'd6',
              ldam  => 'd8',
              tohit => '0',
              type  => 'silver',
            },
            'sling' => {
              sdam  => 'd2',
              ldam  => 'd2',
              tohit => '0',
              type  => 'leather',
            },
            'Snickersnee' => {
              sdam  => 'd10+d8',
              ldam  => 'd12+d8',
              tohit => '1',
              type  => 'iron',
            },
            'spear' => {
              sdam  => 'd6',
              ldam  => 'd8',
              tohit => '0',
              type  => 'iron',
            },
            'spetum' => {
              sdam  => 'd6+1',
              ldam  => '2d6',
              tohit => '0',
              type  => 'iron',
            },
            'Staff of Aesculapius' => {
              sdam  => 'd6',
              ldam  => 'd6',
              tohit => '0',
              type  => 'wood',
            },
            'stiletto' => {
              sdam  => 'd3',
              ldam  => 'd2',
              tohit => '0',
              type  => 'iron',
            },
            'Sting' => {
              sdam  => 'd5',
              ldam  => 'd3',
              tohit => 'd5+2',
              type  => 'wood',
            },
            'Stormbringer' => {
              sdam  => '2d4+d2',
              ldam  => 'd6+d2+1',
              tohit => 'd5',
              type  => 'iron',
            },
            'Sunsword' => {
              sdam  => 'd8',
              ldam  => 'd12',
              tohit => 'd5',
              type  => 'iron',
            },
            'trident' => {
              sdam  => 'd6+1',
              ldam  => '3d4',
              tohit => '0',
              type  => 'iron',
            },
            'Trollsbane' => {
              sdam  => '2d4',
              ldam  => 'd6+1',
              tohit => 'd5',
              type  => 'iron',
            },
            'tsurugi' => {
              sdam  => 'd16',
              ldam  => 'd8+2d6',
              tohit => '2',
              type  => 'metal',
            },
            'The Tsurugi of Muramasa' => {
              sdam  => 'd16+d8',
              ldam  => '2d8+2d6',
              tohit => '2',
              type  => 'metal',
            },
            'two-handed sword' => {
              sdam  => 'd12',
              ldam  => '3d6',
              tohit => '0',
              type  => 'iron',
            },
            'unicorn horn' => {
              sdam  => 'd12',
              ldam  => 'd12',
              tohit => '1',
              type  => 'bone',
            },
            'Vorpal Blade' => {
              sdam  => 'd8+1',
              ldam  => 'd12+1',
              tohit => 'd5',
              type  => 'iron',
            },
            'voulge' => {
              sdam  => '2d4',
              ldam  => '2d4',
              tohit => '0',
              type  => 'iron',
            },
            'war hammer' => {
              sdam  => 'd4+1',
              ldam  => 'd4',
              tohit => '0',
              type  => 'iron',
            },
            'Werebane' => {
              sdam  => 'd8',
              ldam  => 'd8',
              tohit => 'd2',
              type  => 'silver',
            },
            'worm tooth' => {
              sdam  => 'd2',
              ldam  => 'd2',
              tohit => '0',
              type  => 'none',
            },
            'ya' => {
              sdam  => 'd7',
              ldam  => 'd7',
              tohit => '1',
              type  => 'metal',
            },
            'yumi' => {
              sdam  => 'd2',
              ldam  => 'd2',
              tohit => '0',
              type  => 'wood',
            },
        };
        # Japanese name mappings
        $weapons->{'wakizashi'} = $weapons->{'short sword'};
        $weapons->{'ninja-to'}  = $weapons->{'broadsword'};
        $weapons->{'nunchaku'}  = $weapons->{'flail'};
        $weapons->{'naginata'}  = $weapons->{'glaive'};
        $weapons->{'shito'}     = $weapons->{'knife'};
        return $weapons;
    },
);

sub weapon {
    my $self = shift;
    my $arg  = shift;
    return $self->weaponlist->{$arg};
}

1;

