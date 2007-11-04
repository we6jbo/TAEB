#!/usr/bin/env perl
package TAEB::Brain::NhBot;
use Moose;
extends 'TAEB::Brain';

=head1 NAME

TAEB::Brain::NhBot - Know thy roots

=head1 VERSION

Version 0.01 released ???

=cut

our $VERSION = '0.01';

=head2 next_action TAEB -> STRING

Pray when Weak. #enhance when able.

If something is attacking TAEB, ; around the eight adjacent points to find it.
Then repeatedly attack it.

Otherwise, random walk.

=head3 State

What is the last direction we used ; in? Used as an index into the directions
array.

What monster last attacked us? That's the one we're looking for.

=cut

has last_direction => (
    is => 'rw',
    isa => 'Int',
);

has looking_for => (
    is => 'rw',
    isa => 'Str',
);

my @directions = (qw(h j k l y u b n), ' ');

sub random {
    return $directions[rand @directions];
}

sub next_action {
    my $self = shift;
    my $taeb = shift;

    # need food. must pray
    if ($taeb->vt->topline =~ /You (?:are beginning to )?feal weak\./) {
        return "#pray\n";
    }
    # working out is useful for those floating eyes
    elsif ($taeb->vt->topline =~ /You feel more confident/) {
        return "#enhance\na a \n";
    }
    # we just swiped at something, swing again in the same direction
    elsif ($taeb->vt->topline =~ /you (?:just )?(?:hit|miss) (?:(?:the |an? )([-.a-z ]+?)|it)[.!]/i) {
        return 'F' . $directions[$self->last_direction];
    }
    # under attack! start responding
    elsif ($taeb->vt->topline =~ /(?:(?:the |an? )([-.a-z ]+?)|it) (?:just )?(strikes|hits|misses|bites|grabs|stings|touches|points at you, then curses)(?:(?: at)? you(?:r displaced image)?)?[.!]/i) {
        $self->last_direction(-1);
        $self->looking_for($1);
        return $self->spin;
    }
    # looks like the output of ;
    elsif ($taeb->vt->topline =~ /^.\s*.*\(.*\)\s*$/) {
        my $looking_for = $self->looking_for;
        if ($taeb->vt->topline =~ /\Q$looking_for/) {
            # attack!
            return 'F' . $directions[$self->last_direction];
        }

        # ran out of directions and couldn't find it. gulp. just start moving
        # again
        if ($directions[$self->last_direction+1] eq ' ') {
            return $self->random;
        }

        # keep looking..
        return $self->spin;
    }
    else {
        return $self->random;
    }
}

sub spin {
    my $self = shift;
    $self->last_direction($self->last_direction + 1);
    return ';' . $directions[$self->last_direction] . '.';
}

1;

