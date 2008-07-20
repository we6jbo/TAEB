#!perl
package TAEB;
use Curses ();

use TAEB::Util ':colors';

use TAEB::OO;

use Log::Dispatch;
use Log::Dispatch::File;

use TAEB::Config;
use TAEB::VT;
use TAEB::ScreenScraper;
use TAEB::Spoilers;
use TAEB::Knowledge;
use TAEB::World;
use TAEB::Senses;
use TAEB::Action;
use TAEB::Publisher;

=head1 NAME

TAEB - Tactical Amulet Extraction Bot

=cut

# report errors to the screen? should only be done while playing NetHack, not
# during REPL or testing
our $ToScreen = 0;

class_has interface => (
    is       => 'rw',
    isa      => 'TAEB::Interface',
    handles  => [qw/read write/],
    lazy     => 1,
    default  => sub {
        use TAEB::Interface::Local;
        TAEB::Interface::Local->new;
    },
);

# set up TAEB::Persistency {{{
# this must be done after the first "class_has" so that container_class is
# defined for TAEB.
do {
    my $container_class = MooseX::ClassAttribute::container_class;
    my $container_meta = $container_class->meta;

    # add the persistent_file method required by the role
    $container_meta->add_method(persistent_file => sub {
        my $state_file = TAEB->config->state_file;
        return unless defined $state_file;
        return join('-', $state_file, TAEB->config->interface);
    });

    Moose::Util::apply_all_roles($container_meta, 'TAEB::Meta::Role::Persistency');
};
# }}}

class_has personality => (
    is       => 'rw',
    isa      => 'TAEB::AI::Personality',
    lazy     => 1,
    default  => sub {
        use TAEB::AI::Personality::Human;
        return TAEB::AI::Personality::Human->new;
    },
    handles  => [qw(want_item currently next_action)],
    trigger  => sub {
        my ($self, $personality) = @_;
        TAEB->info("Now using personality $personality.");
        $personality->institute;
    },
);

class_has scraper => (
    is       => 'rw',
    isa      => 'TAEB::ScreenScraper',
    required => 1,
    lazy     => 1,
    default  => sub { TAEB::ScreenScraper->new },
    handles  => [qw(parsed_messages all_messages messages farlook)],
);

class_has config => (
    is       => 'rw',
    isa      => 'TAEB::Config',
    lazy     => 1,
    default  => sub { TAEB::Config->new },
);

class_has vt => (
    is       => 'rw',
    isa      => 'TAEB::VT',
    lazy     => 1,
    required => 1,
    default  => sub {
        my $vt = TAEB::VT->new(cols => 80, rows => 24);
        $vt->option_set(LINEWRAP => 1);
        $vt->option_set(LFTOCRLF => 1);
        return $vt;
    },
    handles  => [qw(topline)],
);

class_has state => (
    is      => 'rw',
    isa     => 'PlayState',
    default => 'logging_in',
);

class_has log => (
    is      => 'ro',
    isa     => 'Log::Dispatch',
    lazy    => 1,
    handles => [qw(debug info warning error critical)],
    default => sub {
        my $format = sub {
            my %args = @_;
            chomp $args{message};
            return sprintf "[%s] <T%s> %s: %s\n",
                           uc($args{level}),
                           TAEB->has_senses ? TAEB->turn : '-',
                           scalar(localtime),
                           $args{message};
        };

        my $dispatcher = Log::Dispatch->new(callbacks => $format);
        for (qw(debug info warning error critical)) {
            $dispatcher->add(
                Log::Dispatch::File->new(
                    name => $_,
                    min_level => $_,
                    filename => "log/$_.log",
                )
            );
        }
        return $dispatcher;
    },
);


class_has dungeon => (
    traits  => [qw/TAEB::Persistent/],
    is      => 'ro',
    isa     => 'TAEB::World::Dungeon',
    default => sub { TAEB::World::Dungeon->new },
    handles => sub {
        my ($attr, $dungeon) = @_;

        my %delegate = map { $_ => $_ }
                       qw{current_level current_tile nearest_level
                          map_like x y z};

        for (map { $_->{name} } $dungeon->compute_all_applicable_methods) {
            $delegate{$_} = $_
                if m{
                    ^
                    (?: each | any | all | grep ) _
                    (?: orthogonal | diagonal | adjacent )
                    (?: _inclusive )?
                    $
                }x;
        }

        return %delegate;
    },
);

class_has single_step => (
    is      => 'rw',
    isa     => 'Bool',
    default => 0,
);

class_has info_to_screen => (
    is      => 'rw',
    isa     => 'Bool',
    default => 0,
);

class_has senses => (
    traits    => [qw/TAEB::Persistent/],
    is        => 'rw',
    isa       => 'TAEB::Senses',
    default   => sub { TAEB::Senses->new },
    handles   => qr/^(?!_check_|msg_|update)/,
    predicate => 'has_senses',
);

class_has inventory => (
    traits  => [qw/TAEB::Persistent/],
    is      => 'rw',
    isa     => 'TAEB::World::Inventory',
    default => sub { TAEB::World::Inventory->new },
    handles => {
        find_item => 'find',
    },
);

class_has spells => (
    traits  => [qw/TAEB::Persistent/],
    is      => 'rw',
    isa     => 'TAEB::World::Spells',
    default => sub { TAEB::World::Spells->new },
    handles => {
        find_spell    => 'find',
        find_castable => 'find_castable',
        knows_spell   => 'knows_spell',
    },
);

class_has publisher => (
    is      => 'rw',
    isa     => 'TAEB::Publisher',
    lazy    => 1,
    default => sub { TAEB::Publisher->new },
    handles => [qw/enqueue_message get_exceptional_response get_response send_at_turn send_in_turns remove_messages menu_select single_select/],
);

class_has action => (
    is        => 'rw',
    isa       => 'TAEB::Action',
    predicate => 'has_action',
);

class_has knowledge => (
    traits  => [qw/TAEB::Persistent/],
    is      => 'rw',
    isa     => 'TAEB::Knowledge',
    default => sub { TAEB::Knowledge->new },
);

class_has new_game => (
    is  => 'rw',
    isa => 'Bool',
    trigger => sub {
        my $self = shift;

        # by the time we have called new_game, we know whether or not we want
        # to load the class from a state file or from defaults. so, do
        # initialization here that should be done each time the app starts.
        $self->debug("calling _app_init");
        # XXX: why doesn't this work?
        #$self->_app_init;
        for my $attr ($self->meta->compute_all_applicable_attributes) {
            next if $attr->is_weak_ref;

            my $reader = $attr->get_read_method_ref;
            my $class = $reader->($self);
            next unless blessed($class) && blessed($class) =~ /^TAEB/;

            if ($class->can('_app_init')) {
                $class->_app_init;
            }
        }
    },
);

class_has pathfinds => (
    is  => 'rw',
    isa => 'Int',
    default => 0,
);

around action => sub {
    my $orig = shift;
    my $self = shift;
    return $orig->($self) unless @_;
    TAEB->publisher->unsubscribe($self->action) if $self->action;
    my $ret = $orig->($self, @_);
    TAEB->publisher->subscribe($self->action);
    return $ret;
};

=head2 iterate

This will perform one input/output iteration of TAEB.

It will return any input it receives, so you can follow along at home.

=cut

sub iterate {
    my $self = shift;

    TAEB->debug("Starting a new step.");

    $self->full_input(1);
    $self->human_input;

    my $method = "handle_" . $self->state;
    $self->$method;
}

sub handle_playing {
    my $self = shift;

    if ($self->has_action && !$self->action->aborted) {
        $self->action->done;
        $self->publisher->send_messages;
    }

    $self->currently('?');
    $self->pathfinds(0);
    $self->action($self->next_action);
    TAEB->info("Current action: " . $self->action);
    $self->write($self->action->run);
}

sub handle_logging_in {
    my $self = shift;

    if ($self->vt->contains("Shall I pick a character's ")) {
        TAEB->info("We are now in NetHack, starting a new character.");
        $self->write('n');
    }
    elsif ($self->topline =~ qr/Choosing Character's Role/) {
        $self->write($self->config->get_role);
    }
    elsif ($self->topline =~ qr/Choosing Race/) {
        $self->write($self->config->get_race);
    }
    elsif ($self->topline =~ qr/Choosing Gender/) {
        $self->write($self->config->get_gender);
    }
    elsif ($self->topline =~ qr/Choosing Alignment/) {
        $self->write($self->config->get_align);
    }
    elsif ($self->topline =~ qr/Restoring save file\.\./) {
        $self->info("We are now in NetHack, restoring a save file.");
        $self->write(' ');
        $self->new_game(0);
    }
    elsif ($self->topline =~ qr/, welcome( back)? to NetHack!/) {
        $self->new_game($1 ? 0 : 1);
        $self->enqueue_message('check');
        $self->enqueue_message('game_started');
        $self->state('playing');
    }
    elsif ($self->topline =~ /^\s*It is written in the Book of /) {
        TAEB->error("Using etc/TAEB.nethackrc is MANDATORY");
        $self->quit;
        die "Using etc/TAEB.nethackrc is MANDATORY";
    }
}

sub handle_saving { shift->save }

=head2 full_input

Run a full input loop, sending messages, updating the screen, and so on.

=cut

sub full_input {
    my $self = shift;
    my $main_call = shift;

    $self->scraper->clear;

    $self->process_input;

    unless ($self->state eq 'logging_in') {
        $self->action->post_responses
            if $main_call && $self->has_action && !$self->action->aborted;

        $self->dungeon->update($main_call);
        $self->senses->update($main_call);
        $self->publisher->update($main_call);

        $self->redraw;
        $self->display_topline;
    }
}

=head2 process_input [Bool]

This will read the interface for input, update the VT object, and print.

It will also return any input it receives.

If the passed in boolean is false, no scraping will occur. If no boolean is
provided, or if the boolean is true, then the scraping will go down.

=cut

sub process_input {
    my $self = shift;
    my $scrape = @_ ? shift : 1;

    my $input = $self->read;

    $self->vt->process($input);

    $self->scraper->scrape
        if $scrape && $self->state ne 'logging_in';

    return $input;
}

sub human_input {
    my $self = shift;

    my $c = $self->single_step ? $self->get_key : $self->try_key
        unless $self->personality->meta->name =~ /\bHuman\b/;

    if (defined $c) {
        my $out = $self->keypress($c);
        if (defined $out) {
            $self->notify($out);
        }
    }
}

=head2 keypress Str

This accepts a key (such as one typed by the meatbag at the terminal) and does
something with it.

=cut
sub keypress {
    my $self = shift;
    my $c = shift;

    # refresh modules
    if ($c eq 'r') {
        return "Module::Refresh is broken. Sorry.";
    }

    # pause for a key
    if ($c eq 'p') {
        TAEB->notify("Paused.", 0);
        TAEB->get_key;
        TAEB->redraw;
        return undef;
    }

    # turn on/off step mode
    if ($c eq 's') {
        $self->single_step(not $self->single_step);
        return "Single step mode "
             . ($self->single_step ? "enabled." : "disabled.");
    }

    if ($c eq 'd') {
        my @drawmodes = qw/normal debug pathfind/;
        for (0 .. $#drawmodes) {
            if ($self->config->draw eq $drawmodes[$_]) {
                $self->config->draw($drawmodes[($_+1) % @drawmodes]);
                return undef;
            }
        }

        $self->config->draw('normal');
        return undef;
    }

    if ($c eq 'f') {
        if ($self->config->display_method eq 'floor')
        {
            $self->config->display_method('glyph');
            return "Changing display method back to glyph.";
        }
        else {
            $self->config->display_method('floor');
            return "Changing display method to floor.";
        }
        return undef;
    }

    # turn on/off info to screen
    if ($c eq 'i') {
        $self->info_to_screen(!$self->info_to_screen);
        return "Info to screen " . ($self->info_to_screen ? "on." : "off.");
    }

    # user input (for emergencies only)
    if ($c eq "\e") {
        $self->write($self->get_key);
        return undef;
    }

    # refresh NetHack's screen
    if ($c eq "\cr") {
        # back to normal
        TAEB->redraw(force_clear => 1);
        return undef;
    }

    # console
    if ($c eq '~') {
        $self->console;

        return;
    }

    if ($c eq 'q') {
        $self->state('saving');
        return;
    }

    if ($c eq 'Q') {
        $self->quit;
        return;
    }

    if ($c eq ';') {
        $self->debug_map;
        return;
    }

    # space is always a noncommand
    return if $c eq ' ';

    return "Unknown command '$c'";
}

after qw/info warning/ => sub {
    my ($logger, $message) = @_;

    if (TAEB->info_to_screen && $TAEB::ToScreen) {
        TAEB->notify($message);
    }
};

# don't squelch warnings entirely during tests
after warning => sub {
    my ($logger, $message) = @_;

    if (!$TAEB::ToScreen) {
        local $SIG{__WARN__};
        warn $message;
    }
};

# we want stack traces for errors and crits
around qw/error critical/ => sub {
    my $orig = shift;
    my ($logger, $message) = @_;

    $logger->$orig(Carp::longmess($message));
};

after qw/error critical/ => sub {
    my ($logger, $message) = @_;

    if ($TAEB::ToScreen) {
        TAEB->complain(Carp::shortmess($message));
    }
    else {
        confess $message;
    }
};

sub _notify {
    my $self  = shift;
    my $msg   = shift;
    my $attr  = shift;
    my $sleep = @_ ? shift : 3;

    return if !defined($msg) || !length($msg);

    # strip off extra lines, it's too distracting
    $msg =~ s/\n.*//s;

    Curses::move(1, 0);
    Curses::attron($attr);
    Curses::addstr($msg);
    Curses::attroff($attr);
    Curses::clrtoeol;

    # using TAEB->x and TAEB->y here could screw up horrifically if the dungeon
    # object isn't loaded yet, and loading it calls notify..
    $self->place_cursor(TAEB->vt->x, TAEB->vt->y);

    return if $sleep == 0;

    sleep $sleep;
    $self->redraw;
}

sub notify {
    my $self = shift;
    my $msg  = shift;

    $self->_notify($msg, Curses::COLOR_PAIR(TAEB::Util::COLOR_CYAN), @_);
}

sub complain {
    my $self = shift;
    my $msg  = shift;
    $self->_notify($msg, Curses::COLOR_PAIR(TAEB::Util::COLOR_RED), @_);
}

around write => sub {
    my $orig = shift;
    my $self = shift;
    my $text = shift;

    return if length($text) == 0;

    $self->debug("Sending '$text' to NetHack.");
    $orig->($self, $text);
};

# allow the user to say TAEB->personality("human") and have it DTRT
around personality => sub {
    my $orig = shift;
    my $self = shift;

    if (@_ && (my $personality = $self->personality)) {
        $personality->deinstitute;
    }

    if (@_ && $_[0] =~ /^\w+$/) {
        my $name = shift;

        # guess the case unless they tell us what it is (because of ScoreWhore)
        $name = "\L\u$name" if $name eq lc $name;

        $name = "TAEB::AI::Personality::$name";

        (my $file = "$name.pm") =~ s{::}{/}g;
        require $file;

        return $self->$orig($name->new);
    }

    return $self->$orig(@_);
};

sub new_item {
    my $self = shift;
    TAEB::World::Item->new_item(@_);
}

sub new_monster {
    my $self = shift;
    TAEB::World::Monster->new(@_);
}

sub console {
    my $self = shift;

    eval {
        local $SIG{__DIE__};

        $ENV{PERL_RL} ||= TAEB->config->readline;

        Curses::def_prog_mode();
        Curses::endwin();

        print "\n"
            . "\e[1;37m+"
            . "\e[1;30m" . ('-' x 50)
            . "\e[1;37m[ "
            . "\e[1;36mT\e[0;36mAEB \e[1;36mC\e[0;36monsole"
            . " \e[1;37m]"
            . "\e[1;30m" . ('-' x 12)
            . "\e[1;37m+"
            . "\e[m\n";

        no warnings 'redefine';
        require Devel::REPL::Script;
        local $TAEB::ToScreen;

        eval {
            local $SIG{INT} = sub { die "Interrupted." };
            Devel::REPL::Script->new->run;
        };
    };

    # we really do need to do this twice. my amateur opinion is that curses
    # isn't fully re-initialized when we call it the first time. oh well.
    $self->redraw(force_clear => 1) for 1..2;
}

sub debug_map {
    my $self = shift;

    my ($x, $y) = ($self->x, $self->y);
    my $level = $self->current_level;
    my $z_index = 0;

    $self->redraw(botl => "Displaying $level");

    COMMAND: while (1) {
        my $tile = $level->at($x, $y);

        Curses::move(0, 0);
        # draw some info about the tile at the top
        Curses::addstr($tile->debug_line);
        Curses::clrtoeol;
        $self->place_cursor($x, $y);

        # where to next?
        my $c = $self->get_key;

           if ($c eq 'h') { --$x }
        elsif ($c eq 'j') { ++$y }
        elsif ($c eq 'k') { --$y }
        elsif ($c eq 'l') { ++$x }
        elsif ($c eq 'y') { --$x; --$y }
        elsif ($c eq 'u') { ++$x; --$y }
        elsif ($c eq 'b') { --$x; ++$y }
        elsif ($c eq 'n') { ++$x; ++$y }
        elsif ($c eq 'H') { $x -= 8 }
        elsif ($c eq 'J') { $y += 8 }
        elsif ($c eq 'K') { $y -= 8 }
        elsif ($c eq 'L') { $x += 8 }
        elsif ($c eq 'Y') { $x -= 8; $y -= 8 }
        elsif ($c eq 'U') { $x += 8; $y -= 8 }
        elsif ($c eq 'B') { $x -= 8; $y += 8 }
        elsif ($c eq 'N') { $x += 8; $y += 8 }
        elsif ($c eq ';' || $c eq '.' || $c eq "\e"
            || $c eq "\n" || $c eq ' ' || $c eq 'q' || $c eq 'Q') {
            last;
        }
        elsif ($c eq '<' || $c eq '>') {
            my $dz = $c eq '<' ? -1 : 1;

            # if we don't filter out these levels, then levels consisting of
            # just rock will make it through, because we initialize those
            # (apparently!)
            my @levels = grep { $_->turns_spent_on > 0 }
                         $self->dungeon->get_levels($level->z + $dz);
            next COMMAND if @levels == 0;

            $level = sub {
                # only one level, easy choice
                if (@levels == 1) {
                    return $levels[0];
                }

                # try to stay in the same branch
                for (@levels) {
                    return $_ if $_->branch eq $level->branch;
                }

                # or go to a level with an unknown branch
                for (@levels) {
                    return $_ if !$_->has_branch;
                }

                # finally, pick a level arbitrarily
                return $levels[0];
            }->();

            $z_index = 0;

            $self->redraw(level => $level, botl => "Displaying $level");

            if (@levels > 1) {
                Curses::move(1, 0);
                Curses::addstr("Note: there are " . @levels . " levels at this depth. Use v to see the next.");
                Curses::clrtoeol;
            }
        }
        elsif ($c eq 'v') {
            my @levels = grep { $_->turns_spent_on > 0 }
                         $self->dungeon->get_levels($level->z);
            next COMMAND if @levels < 2;

            $level = $levels[++$z_index % @levels];
            $self->redraw(level => $level, botl => "Displaying $level");
        }

        $x %= 80;
        $y = ($y-1)%21+1;
    }

    # back to normal
    $self->redraw;
    return;
}


sub get_key { Curses::getch }

sub try_key {
    my $self = shift;

    Curses::nodelay(Curses::stdscr, 1);
    my $c = Curses::getch;
    Curses::nodelay(Curses::stdscr, 0);

    return undef if $c eq -1;
    return $c;
}

sub redraw {
    my $self = shift;
    my %args = @_;

    if ($args{force_clear}) {
        Curses::clear;
        Curses::refresh;
    }

    my $level  = $args{level} || TAEB->current_level;
    my $draw   = 'draw_'.(TAEB->config->draw || 'normal');
    my $method = 'display_'.(TAEB->config->display_method || 'glyph');

    for my $y (1 .. 21) {
        Curses::move($y, 0);
        for my $x (0 .. 79) {
            $level->at($x, $y)->$draw($method);
        }
    }

    $self->draw_botl($args{botl}, $args{status});
    $self->place_cursor;
}

sub draw_botl {
    my $self   = shift;
    my $botl   = shift;
    my $status = shift;

    return unless $self->state eq 'playing';

    Curses::move(22, 0);

    if (!$botl) {
        my $command = $self->has_action ? $self->action->command : '?';
        $command =~ s/\n/\\n/g;
        $command =~ s/\e/\\e/g;
        $command =~ s/\cd/^D/g;

        $botl = $self->checking
              ? "Checking " . $self->checking
              : $self->currently . " ($command)";
    }

    Curses::addstr($botl);

    Curses::clrtoeol;
    Curses::move(23, 0);

    if (!$status) {
        my @pieces;
        push @pieces, 'D:' . $self->current_level->z;
        $pieces[-1] .= uc substr($self->current_level->branch, 0, 1)
            if $self->current_level->known_branch;
        $pieces[-1] .= ' ('. ucfirst($self->current_level->special_level) .')'
            if $self->current_level->special_level;

        push @pieces, 'H:' . $self->hp;
        $pieces[-1] .= '/' . $self->maxhp
            if $self->hp != $self->maxhp;

        if ($self->spells->has_spells) {
            push @pieces, 'P:' . $self->power;
            $pieces[-1] .= '/' . $self->maxpower
                if $self->power != $self->maxpower;
        }

        push @pieces, 'A:' . $self->ac;
        push @pieces, 'X:' . $self->level;
        push @pieces, 'N:' . $self->nutrition;
        push @pieces, 'T:' . $self->turn;
        push @pieces, 'S:' . $self->score
            if $self->has_score;
        push @pieces, '$' . $self->gold;
        push @pieces, 'P:' . $self->pathfinds;

        my $statuses = join '', map { ucfirst substr $_, 0, 2 } $self->statuses;
        push @pieces, '[' . $statuses . ']'
            if $statuses;

        $status = join ' ', @pieces;
    }

    Curses::addstr($status);
    Curses::clrtoeol;
}

sub place_cursor {
    my $self = shift;
    my $x    = shift || TAEB->x;
    my $y    = shift || TAEB->y;

    Curses::move($y, $x);
    Curses::refresh;
}

sub display_topline {
    my $self = shift;
    my @messages = $self->parsed_messages;

    if (@messages == 0) {
        # we don't need to worry about the other rows, the map will
        # overwrite them
        Curses::move 0, 0;
        Curses::clrtoeol;
        $self->place_cursor;
        return;
    }

    while (my @msgs = splice @messages, 0, 20) {
        my $y = 0;
        for (@msgs) {
            my ($line, $matched) = @$_;

            if (TAEB->config->spicy
            &&  TAEB->config->spicy ne 'hold back on the chili, please') {
                my @spice = (
                    'rope golem',                'rape golem',             0.2,
                    'oil lamp',                  'Garin',                  0.5,
                    '\bhit',                     'roundhouse-kick',        0.02,
                    'snoring snakes',            'Eidolos taking a nap',   1,
                    'hear a strange wind',   'smell Eidolos passing wind', 1,
                    qr/(?:jackal|wolf) howling/, 'Eidolos howling',        1,
                );

                while (my ($orig, $sub, $prob) = splice @spice, 0, 3) {
                    $line =~ s/$orig/$sub/ if rand() < $prob;
                }
            }

            my $chopped = length($line) > 75;
            $line = substr($line, 0, 75);

            Curses::move $y++, 0;

            my $color = $matched
                      ? Curses::COLOR_PAIR(COLOR_GREEN)
                      : Curses::COLOR_PAIR(COLOR_BROWN);

            Curses::attron($color);
            Curses::addstr($line);
            Curses::attroff($color);

            Curses::addstr '...' if $chopped;

            Curses::clrtoeol;
        }

        if (@msgs > 1) {
            $self->place_cursor;
            #sleep 1;
            #sleep 2 if @msgs > 5;
            TAEB->redraw if @messages;
        }
    }
    $self->place_cursor;
}

sub quit {
    my $self = shift;
    $self->write("   \e   \e     #quit\ny");
}

sub save {
    shift->write("   \e   \e     Sy");
    die "See you soon!";
}

sub died {
    my $self = shift;
    $self->dead(1);
    $self->destroy_saved_state;

    # this REALLY prevents us from saving the state file
    $self->config->state_file(undef);
}

__PACKAGE__->meta->make_immutable;
MooseX::ClassAttribute::container_class->meta->make_immutable;
no Moose;
no MooseX::ClassAttribute;

1;

