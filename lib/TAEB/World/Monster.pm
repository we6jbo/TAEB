#!/usr/bin/env perl
package TAEB::World::Monster;
use TAEB::OO;
use TAEB::Util qw/:colors/;

use overload %TAEB::Meta::Overload::default;

has glyph => (
    isa      => 'Str',
    required => 1,
);

has color => (
    isa      => 'Str',
    required => 1,
);

has tile => (
    isa      => 'TAEB::World::Tile',
    weak_ref => 1,
    handles  => [qw/x y z/],
);

sub is_shk {
    my $self = shift;
    $self->glyph eq '@' && $self->color eq COLOR_WHITE;
}

sub is_oracle {
    my $self = shift;
    return 0 if TAEB->z < 5 || TAEB->z > 9;
    return 0 unless $self->x == 39 && $self->y == 12;
    return 1 if $self->glyph eq '@' && $self->color eq COLOR_BRIGHT_BLUE;
    return 0;
}

sub is_vault_guard {
    my $self = shift;
    return 0 unless TAEB->following_vault_guard;
    return 1 if $self->glyph eq '@' && $self->color eq COLOR_BLUE;
    return 0;
}

sub is_quest_friendly {
    my $self = shift;

    # Attacking @s in quest level 1 will screw up your quest. So...don't.
    return 1 if TAEB->current_level->branch eq 'quest'
             && TAEB->z == 1
             && $self->glyph eq '@';
    return 0;
}

sub is_enemy {
    my $self = shift;
    return 0 if $self->is_shk;
    return 0 if $self->is_oracle;
    return 0 if $self->is_coaligned_unicorn;
    return 0 if $self->is_vault_guard;
    return 0 if $self->is_watchman;
    return 0 if $self->is_quest_friendly;
    return 1;
}

sub is_meleeable {
    my $self = shift;

    return 0 unless $self->is_enemy;

    # floating eye (paralysis)
    return 0 if $self->color eq COLOR_BLUE
             && $self->glyph eq 'e';

    # blue jelly (cold)
    return 0 if $self->color eq COLOR_BLUE
             && $self->glyph eq 'j'
             && !TAEB->cold_resistant;

    # spotted jelly (acid)
    return 0 if $self->color eq COLOR_GREEN
             && $self->glyph eq 'j';

    return 1;
}

sub is_sleepable {
    my $self = shift;
    return $self->is_meleeable;
}

sub respects_elbereth {
    my $self = shift;

    return 0 if $self->glyph =~ /[A@]/;
    return 0 if $self->is_minotaur;
    # return 0 if $self->is_rider;
    # return 0 if $self->is_blind && !$self->is_permanently_blind;

    return 1;
}

sub is_minotaur {
    my $self = shift;
    $self->glyph eq 'H' && $self->color eq COLOR_BROWN
}

sub is_coaligned_unicorn {
    my $self = shift;
    return 0 if $self->glyph ne 'u';
    return 0 if $self->color eq COLOR_BROWN;

    # this is coded somewhat strangely to deal with black unicorns being
    # blue or dark gray
    if ($self->color eq COLOR_WHITE) {
        return TAEB->align eq 'Law';
    }

    if ($self->color eq COLOR_GRAY) {
        return TAEB->align eq 'Neu';
    }

    return TAEB->align eq 'Cha';
}

sub is_watchman {
    my $self = shift;
    return 0 unless $self->tile->level->is_minetown;
    return 0 unless $self->glyph eq '@';
    return $self->color eq COLOR_GRAY || $self->color eq COLOR_GREEN;
}

sub debug_line {
    my $self = shift;
    my @bits;

    push @bits, sprintf '(%d,%d)', $self->x, $self->y;
    push @bits, 'g<' . $self->glyph . '>';
    push @bits, 'c<' . $self->color . '>';

    return join ' ', @bits;
}

# all monsters are in LOS because we only keep track of monsters in LOS
sub in_los { return 1 }

__PACKAGE__->meta->make_immutable;
no Moose;

1;

