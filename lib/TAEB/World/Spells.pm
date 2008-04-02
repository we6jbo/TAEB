#!/usr/bin/env perl
package TAEB::World::Spells;
use TAEB::OO;
use List::Util 'first';

use overload %TAEB::Meta::Overload::default;

my @slots = ('a' .. 'z', 'A' .. 'Z');

has _spells => (
    metaclass => 'Collection::Hash',
    is        => 'rw',
    isa       => 'HashRef[TAEB::Knowledge::Spell]',
    default   => sub { {} },
    provides  => {
        get    => 'get',
        set    => 'set',
        values => 'spells',
        keys   => 'slots',
        empty  => 'has_spells',
    },
);

sub find {
    my $self = shift;
    my $name = shift;

    return first { $_->name eq $name } $self->spells;
}

sub find_castable {
    my $self = shift;
    my $name = shift;

    my $spell = first { $_->name eq $name } $self->spells;
    return unless $spell && $spell->castable;
    return $spell;
}

sub castable_spells {
    my $self = shift;
    return grep { $_->castable } $self->spells;
}

sub forgotten_spells {
    my $self = shift;
    return grep { $_->forgotten } $self->spells;
}

sub msg_know_spell {
    my $self = shift;
    my ($slot, $name, $forgotten, $fail) = @_;

    my $spell = $self->get($slot);
    if (!defined($spell)) {
        $spell = TAEB::Knowledge::Spell->new(
            name => $name,
            fail => $fail,
            slot => $slot,
        );
        $self->set($slot => $spell);
    }
    else {
        if ($spell->fail != $fail) {
            TAEB->debug("Setting " . $spell->name . "'s failure rate to $fail% (was ". $spell->fail ."%).");
            $spell->fail($fail);
        }
    }

    # update whether we have forgotten the spell or not?
    # this is potentially run when we save and reload
    if ($spell->forgotten xor $forgotten) {
        if ($forgotten) {
            TAEB->debug("Setting " . $spell->name . "'s learned at to 20,001 turns ago (".(TAEB->turn - 20_001)."), was ".$spell->learned_at.".");

            $spell->learned_at(TAEB->turn - 20_001);
        }
        else {
            TAEB->debug("Setting " . $spell->name . "'s learned at to the current turn (".(TAEB->turn)."), was ".$spell->learned_at.".");

            $spell->learned_at(TAEB->turn);
        }
    }
}

sub debug_line {
    my $self = shift;
    my @spells;

    return "No magic." unless $self->has_spells;

    for my $slot (sort $self->slots) {
        push @spells, $self->get($slot);
    }

    return join "\n", @spells;
}

sub knows_spell {
    my $self = shift;
    my $item = shift;

    return 0 unless $item->class eq 'spellbook';
    return 0 unless $item->identity;

    if (my ($name) = $item->identity =~ /^spellbook of (.*)$/) {
        return $self->get($name);
    }

    return;
}

__PACKAGE__->meta->make_immutable;
no Moose;

1;

