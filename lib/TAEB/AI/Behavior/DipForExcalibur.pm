#!/usr/bin/env perl
package TAEB::AI::Behavior::DipForExcalibur;
use TAEB::OO;
extends 'TAEB::AI::Behavior';

sub can_make_excalibur {
    return unless TAEB->align eq 'Law';

    # only one Excalibur. Alas.
    return if TAEB::Spoilers::Item::Artifact->seen("Excalibur");

    return 1;
}

sub prepare {
    my $self = shift;

    return 0 unless $self->can_make_excalibur;

    # are we eligible to dip for Excalibur now?
    return 0 unless TAEB->level >= 5;

    my $longsword = TAEB->find_item("long sword");

    my $level = TAEB->nearest_level(sub {
        my $lvl = shift;
        return 0 if $lvl->is_minetown;
        return $lvl->has_type('fountain');
    });

    return 0 if !$level;
    return 0 if TAEB->current_level->is_minetown;

    # are we standing on a fountain? if so, dip!
    if (TAEB->current_tile->type eq 'fountain') {
        $self->currently("Dipping for Excalibur!");
        $self->do(dip => item => $longsword, into => "fountain");
        return 100;
    }

    # find a fountain
    my $path = TAEB::World::Path->first_match(
        sub { shift->type eq 'fountain' },
        on_level => $level,
    );

    $self->if_path($path => "Heading towards a fountain");
}

sub urgencies {
    return {
        100 => "dipping for Excalibur",
         50 => "path to fountain",
    };
}

sub pickup {
    my $self = shift;
    my $item = shift;

    if ($item->identity eq 'long sword') {
        return unless $self->can_make_excalibur;
        return if TAEB->find_item("long sword");
        return 1;
    }
}

__PACKAGE__->meta->make_immutable;
no Moose;

1;

