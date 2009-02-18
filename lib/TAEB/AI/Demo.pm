package TAEB::AI::Demo;
use TAEB::OO;
extends 'TAEB::AI';

sub next_action {
    my $self = shift;

    for my $name (qw/pray melee hunt descend to_stairs open_door to_door explore search/) {
        my $method = "try_$name";
        my $action = $self->$method;

        next unless $action;

        $self->currently($name);
        return $action;
    }

    # We must be trapped! Search for an exit.
    $self->currently('to_search');
    return $self->to_search;
}

# first, some helper methods
sub find_adjacent {
    my $code = shift;

    my ($tile, $direction);

    TAEB->each_adjacent(sub {
        my ($t, $d) = @_;
        ($tile, $direction) = ($t, $d) if $code->($t, $d);
    });

    return $tile if !wantarray;
    return ($tile, $direction);
}

sub if_adjacent {
    my $code   = shift;
    my $action = shift;

    my ($tile, $direction) = find_adjacent($code);

    return unless $direction;

    # allow coderefs for action to do some additional decisionmaking
    $action = $action->($tile, $direction) if ref($action);

    my $action_class = "TAEB::Action::\u$action";
    return $action_class->new(
        direction => $direction,
    );
}

sub try_pray {
    return unless TAEB->can_pray;

    return unless TAEB->nutrition < 100
               || TAEB->in_pray_heal_range;

    return TAEB::Action::Pray->new;
}

sub try_melee {
    if_adjacent(sub { $_[0]->has_enemy && $_[0]->monster->is_meleeable; },
        'melee',
    );
}

sub try_hunt {
    # look for the nearest tile with a monster
    my $path = TAEB::World::Path->first_match(sub {
        my $tile = shift;

        return $tile->has_enemy
            && $tile->monster->is_meleeable
            && !$tile->monster->is_seen_through_warning
    });

    return unless $path;

    return TAEB::Action::Move->new(
        path => $path,
    );
}

sub try_descend {
    # Can only descend while on stairs down.
    return unless TAEB->current_tile->type eq 'stairsdown';

    # Descend!
    return TAEB::Action::Descend->new;
}

sub try_to_stairs {
    # look for the nearest tile with a down staircase
    my $path = TAEB::World::Path->first_match(sub {
        shift->type eq 'stairsdown'
    });

    return unless $path;

    return TAEB::Action::Move->new(
        path => $path,
    );
}

sub try_open_door {
    if_adjacent(sub { shift->type eq 'closeddoor' },
        sub {
            my $door = shift;
            return 'kick' if $door->is_locked;
            return 'open';
        },
    );
}

sub try_to_door {
    # look for the nearest tile with a closed door
    my $path = TAEB::World::Path->first_match(sub {
        shift->type eq 'closeddoor'
    });

    return unless $path;

    return TAEB::Action::Move->new(
        path => $path,
    );
}

sub try_explore {
    # look for the nearest tile that isn't explored
    my $path = TAEB::World::Path->first_match(sub {
        not shift->explored
    });

    return unless $path;

    return TAEB::Action::Move->new(
        path => $path,
    );
}

sub try_search {
    if_adjacent(sub { shift->searched < 30 } => 'search');
}

sub to_search {
    # look for the nearest tile that isn't sufficiently searched.
    my $path = TAEB::World::Path->first_match(sub {
        shift->searched < 30
    });

    return TAEB::Action::Move->new(
        path => $path,
    );
}

__PACKAGE__->meta->make_immutable;
no TAEB::OO;

1;

__END__

=head1 NAME

TAEB::AI::Demo - a demonstration autonomous AI

=head1 DESCRIPTION

This is so we can have something that *plays* NetHack in the core TAEB distro,
a default AI. We could use L<TAEB::AI::Behavioral> but that is a separate
distribution so it's not a great idea.

This is also an example AI for people interested in writing one.

=cut

