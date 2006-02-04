##################################################################
#     $URL$
#    $Date$
#   $Author$
# $Revision$
##################################################################

use strict;
use warnings;
use File::Spec;
use Test::More tests => 29;

#-----------------------------------------------------------------------------
#Load perlcritic like a library so we can test its subroutines

my $perlcritic = File::Spec->catfile( qw(blib script perlcritic) );
require $perlcritic;  ## no critic

#-----------------------------------------------------------------------------

local @ARGV = qw(-1 -2 -3 -4 -5);
my %options = get_options();
is( $options{-severity}, 1);

local @ARGV = qw(-5 -3 -4 -1 -2);
%options = get_options();
is( $options{-severity}, 1);

local @ARGV = qw();
%options = get_options();
is( $options{-severity}, undef);

local @ARGV = qw(-2 -4 -severity 5);
%options = get_options();
is( $options{-severity}, 2);

local @ARGV = qw(-severity 5 -2 -1); 
%options = get_options();
is( $options{-severity}, 1);

#-----------------------------------------------------------------------------

local @ARGV = qw(-top); 
%options = get_options();
is( $options{-severity}, 1);
is( $options{-top}, 20);

local @ARGV = qw(-top 10); 
%options = get_options();
is( $options{-severity}, 1);
is( $options{-top}, 10);

local @ARGV = qw(-severity 4 -top); 
%options = get_options();
is( $options{-severity}, 4);
is( $options{-top}, 20);

local @ARGV = qw(-severity 4 -top 10); 
%options = get_options();
is( $options{-severity}, 4);
is( $options{-top}, 10);

local @ARGV = qw(-severity 5 -2 -top 5); 
%options = get_options();
is( $options{-severity}, 2);
is( $options{-top}, 5);

#-----------------------------------------------------------------------------

local @ARGV = qw(-noprofile); 
%options = get_options();
is( $options{-profile}, q{});

local @ARGV = qw(-profile foo); 
%options = get_options();
is( $options{-profile}, 'foo');

#-----------------------------------------------------------------------------

local @ARGV = qw(-verbose 2); 
%options = get_options();
is( $options{-verbose}, 2);

local @ARGV = qw(-verbose %l:%c:%m); 
%options = get_options();
is( $options{-verbose}, '%l:%c:%m');

#-----------------------------------------------------------------------------

my @perl_files = qw(foo.t foo.pm foo.pl foo.PL);
for (@perl_files){
        ok( _is_perl($_), 'Is perl' );
}

my @not_perl_files = qw(foo.doc foo.txt foo.conf foo);
for (@not_perl_files){
        ok( !_is_perl($_), 'Is not perl' );
}

#-----------------------------------------------------------------------------

ok( _interpolate( '\r%l\t%c\n' ) eq "\r%l\t%c\n", 'Interpolation' );
ok( _interpolate( 'literal'    ) eq "literal",    'Interpolation' );

#-----------------------------------------------------------------------------