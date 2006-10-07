##################################################################
#     $URL$
#    $Date$
#   $Author$
# $Revision$
##################################################################

use strict;
use warnings;
use Test::More tests => 14;

# common P::C testing tools
use Perl::Critic::TestUtils qw(pcritique);
Perl::Critic::TestUtils::block_perlcriticrc();

my $code ;
my $policy;
my %config;

#----------------------------------------------------------------

$code = <<'END_PERL';
my $fooBAR;
my ($fooBAR) = 'nuts';
local $FooBar;
our ($FooBAR);
END_PERL

$policy = 'NamingConventions::ProhibitMixedCaseVars';
is( pcritique($policy, \$code), 4, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
my ($foobar, $fooBAR);
my (%foobar, @fooBAR, $foo);
local ($foobar, $fooBAR);
local (%foobar, @fooBAR, $foo);
our ($foobar, $fooBAR);
our (%foobar, @fooBAR, $foo);
END_PERL

$policy = 'NamingConventions::ProhibitMixedCaseVars';
is( pcritique($policy, \$code), 6, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
my $foo_BAR;
my $FOO_BAR;
my $foo_bar;

# These come from other packages,
# so we can't really complain
# about the naming convention.
local $Other::Package::foo_BAR;
$Other::Package::foo_BAR;
local $Other::Package::fooBAR;
$Some::Package::fooBAR;

END_PERL

$policy = 'NamingConventions::ProhibitMixedCaseVars';
is( pcritique($policy, \$code), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
my ($foo_BAR, $BAR_FOO);
my ($foo_BAR, $BAR_FOO) = q(this, that);
our (%FOO_BAR, @BAR_FOO);
local ($FOO_BAR, %BAR_foo) = @_;
my ($foo_bar, $foo);
END_PERL

$policy = 'NamingConventions::ProhibitMixedCaseVars';
is( pcritique($policy, \$code), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
sub fooBAR {}
sub FooBar {}
sub Foo_Bar {}
sub FOObar {}
END_PERL

$policy = 'NamingConventions::ProhibitMixedCaseSubs';
is( pcritique($policy, \$code), 4, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
sub foo_BAR {}
sub foo_bar {}
sub FOO_bar {}
sub Foo::Bar::grok {}
END_PERL

$policy = 'NamingConventions::ProhibitMixedCaseSubs';
is( pcritique($policy, \$code), 0, $policy);

#----------------------------------------------------------------

# Use all of the forbidden names in slightly different ways
# The test should catch all of them
$code = <<'END_PERL';
my $left = 1;          # scalar
my @right = ('foo');   # array
our $no = undef;       # our
my %abstract;          # hash
local *main::contract; # pkg prefix on var
sub record {}          # sub
my ($second, $close);  # catch both of these
sub pkg::bases {}      # pkg prefix on sub
my ($last, $set);
END_PERL

$policy = 'NamingConventions::ProhibitAmbiguousNames';
is( pcritique($policy, \$code), 11, $policy);

#----------------------------------------------------------------

# word fragments
$code = <<'END_PERL';
my $last_record;
END_PERL

$policy = 'NamingConventions::ProhibitAmbiguousNames';
TODO: {

    #TODO blocks don't seem to work properly with the Test::Harness
    #that I have at work. So for now, I'm just going to disable these tests.

    #local $TODO = 'false negative: do not allow ambiguous words in compound names like "last_record"';
    #is( pcritique($policy, \$code), 1, $policy);
    1;
}

#----------------------------------------------------------------

# These are not forbidden usages
$code = <<'END_PERL';
for my $bases () {}
print $main::contract;
local $\; # for Devel::Cover; an example of a var declaration without \w
END_PERL

$policy = 'NamingConventions::ProhibitAmbiguousNames';
is( pcritique($policy, \$code), 0, $policy);

#----------------------------------------------------------------

# These are not forbidden usages
$code = <<'END_PERL';
my ($foo) = ($left);
END_PERL

$policy = 'NamingConventions::ProhibitAmbiguousNames';
TODO: {

    #TODO blocks don't seem to work properly with the Test::Harness
    #that I have at work. So for now, I'm just going to disable these tests.

    #local $TODO = 'false positive: need to distinguish rhs in variable statements';
    #is( pcritique($policy, \$code), 0, $policy);
    1;
}

#----------------------------------------------------------------

# These are not forbidden names
$code = <<'END_PERL';
my %hash = (left => 1, center => 'right');
sub no_left_turn {}
close $fh;
END_PERL

$policy = 'NamingConventions::ProhibitAmbiguousNames';
is( pcritique($policy, \$code), 0, $policy);

#----------------------------------------------------------------

# These ambiguous but standard names should be allowed
$code = <<'END_PERL';
no warnings;
close $fh;
END_PERL

$policy = 'NamingConventions::ProhibitAmbiguousNames';
is( pcritique($policy, \$code), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
my $left;
my $close;
END_PERL

%config = (forbid => q{});
$policy = 'NamingConventions::ProhibitAmbiguousNames';
is( pcritique($policy, \$code, \%config), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
my $left;
my $close;
my $foo;
my $bar;
END_PERL

%config = (forbid => q{foo bar baz quux});
$policy = 'NamingConventions::ProhibitAmbiguousNames';
is( pcritique($policy, \$code, \%config), 2, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
my $left;
my $close;
my $foo;
my $bar;
END_PERL

my @default = Perl::Critic::Policy::NamingConventions::ProhibitAmbiguousNames::default_forbidden_words();
%config = ( forbid => join q{ }, qw(foo bar baz quux), @default );
$policy = 'NamingConventions::ProhibitAmbiguousNames';
is( pcritique($policy, \$code, \%config), 4, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
my $left;
my $close;
END_PERL

%config = (forbid => undef);
$policy = 'NamingConventions::ProhibitAmbiguousNames';
is( pcritique($policy, \$code, \%config), 2, $policy);
