#!perl

##################################################################
#     $URL$
#    $Date$
#   $Author$
# $Revision$
##################################################################

use strict;
use warnings;
use Test::More tests => 18;
use Perl::Critic::Defaults;


{
    my $d = Perl::Critic::Defaults->new();
    is($d->force(),    0,           'native default force');
    is($d->nocolor(),  0,           'native default nocolor');
    is($d->only(),     0,           'native default only');
    is($d->severity(), 5,           'native default severity');
    is($d->theme(),    q{},         'native default theme');
    is($d->top(),      0,           'native default top');
    is($d->verbose(),  3,           'native default verbose');
    is_deeply($d->include(), [],    'native default include');
    is_deeply($d->exclude(), [],    'native default exclude');
}

#-----------------------------------------------------------------------------

{
    my %user_defaults = (
         -force => undef,
         -nocolor => undef,
         -only => undef,
         -severity => 4,
         -theme => 'pbp',
         -top => 50,
         -verbose => 7,
         -include => 'foo bar',
         -exclude => 'baz nuts',
    );

    my $d = Perl::Critic::Defaults->new( %user_defaults );
    is($d->force(),    1,           'user default force');
    is($d->nocolor(),  1,           'user default nocolor');
    is($d->only(),     1,           'user default only');
    is($d->severity(), 4,           'user default severity');
    is($d->theme(),    'pbp',       'user default theme');
    is($d->top(),      50,          'user default top');
    is($d->verbose(),  7,           'user default verbose');
    is_deeply($d->include(), [ qw(foo bar) ], 'user default include');
    is_deeply($d->exclude(), [ qw(baz nuts)], 'user default exclude');
}

