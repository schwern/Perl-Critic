#!perl

##############################################################################
#     $URL$
#    $Date$
#   $Author$
# $Revision$
##############################################################################

use 5.006001;
use strict;
use warnings;

use Test::More (tests => 28);
use Perl::Critic::PolicyFactory (-test => 1);

# common P::C testing tools
use Perl::Critic::TestUtils qw(critique);

#-----------------------------------------------------------------------------

our $VERSION = '1.090';

#-----------------------------------------------------------------------------

Perl::Critic::TestUtils::block_perlcriticrc();

# Configure Critic not to load certain policies.  This
# just makes it a little easier to create test cases
my $profile = {
    '-CodeLayout::RequireTidyCode'                               => {},
    '-Documentation::PodSpelling'                                => {},
    '-ErrorHandling::RequireCheckingReturnValueOfEval'           => {},
    '-Miscellanea::RequireRcsKeywords'                           => {},
    '-ValuesAndExpressions::ProhibitMagicNumbers'                => {},
    '-ValuesAndExpressions::RequireConstantOnLeftSideOfEquality' => {},
};

my $code = undef;

#-----------------------------------------------------------------------------

$code = <<'END_PERL';
package FOO;
use strict;
use warnings;
our $VERSION = 1.0;

require 'some_library.pl';  ## no critic
print $crap if $condition;  ## no critic

1;
END_PERL

is(
    critique(
        \$code,
        {-profile => $profile, -severity => 1, -theme => 'core'}
    ),
    0,
    'inline no-critic'
);

#-----------------------------------------------------------------------------

$code = <<'END_PERL';
package FOO;
use strict;
use warnings;
our $VERSION = 1.0;

$foo = $bar;

## no critic

require 'some_library.pl';
print $crap if $condition;

## use critic

$baz = $nuts;
1;
END_PERL

is(
    critique(
        \$code,
        {-profile => $profile, -severity => 1, -theme => 'core'},
    ),
    0,
    'region no-critic',
);

#-----------------------------------------------------------------------------

$code = <<'END_PERL';
package FOO;
use strict;
use warnings;
our $VERSION = 1.0;

for my $foo (@list) {
  ## no critic
  $long_int = 12345678;
  $oct_num  = 033;
}

my $noisy = '!';

1;
END_PERL

is(
    critique(
        \$code,
        {-profile => $profile, -severity => 1, -theme => 'core'},
    ),
    1,
    'scoped no-critic',
);

#-----------------------------------------------------------------------------

$code = <<'END_PERL';
package FOO;
use strict;
use warnings;
our $VERSION = 1.0;

{
  ## no critic
  $long_int = 12345678;
  $oct_num  = 033;
}

my $noisy = '!';

1;
END_PERL

is(
    critique(
        \$code,
        {-profile => $profile, -severity => 1, -theme => 'core'},
    ),
    1,
    'scoped no-critic',
);

#-----------------------------------------------------------------------------

$code = <<'END_PERL';
package FOO;
use strict;
use warnings;
our $VERSION = 1.0;

## no critic
for my $foo (@list) {
  $long_int = 12345678;
  $oct_num  = 033;
}

## use critic
my $noisy = '!';

1;
END_PERL

is(
    critique(
        \$code,
        {-profile => $profile, -severity => 1, -theme => 'core'},
    ),
    1,
    'region no-critic across a scope',
);

#-----------------------------------------------------------------------------

$code = <<'END_PERL';
package FOO;
use strict;
use warnings;
our $VERSION = 1.0;

for my $foo (@list) {
  ## no critic
  $long_int = 12345678;
  $oct_num  = 033;
  ## use critic
}

my $noisy = '!';
my $empty = '';

1;
END_PERL

is(
    critique(
        \$code,
        {-profile => $profile, -severity => 1, -theme => 'core'},
    ),
    2,
    'scoped region no-critic',
);

#-----------------------------------------------------------------------------

$code = <<'END_PERL';
package FOO;
use strict;
use warnings;
our $VERSION = 1.0;

## no critic
for my $foo (@list) {
  $long_int = 12345678;
  $oct_num  = 033;
}

my $noisy = '!';
my $empty = '';

#No final '1;'
END_PERL

is(
    critique(
        \$code,
        {-profile => $profile, -severity => 1, -theme => 'core'},
    ),
    0,
    'unterminated no-critic across a scope',
);

#-----------------------------------------------------------------------------

$code = <<'END_PERL';
package FOO;
use strict;
use warnings;
our $VERSION = 1.0;

$long_int = 12345678;  ## no critic
$oct_num  = 033;       ## no critic
my $noisy = '!';       ## no critic
my $empty = '';        ## no critic
my $empty = '';        ## use critic

1;
END_PERL

is(
    critique(
        \$code,
        {-profile => $profile, -severity => 1, -theme => 'core'},
    ),
    1,
    'inline use-critic',
);

#-----------------------------------------------------------------------------

$code = <<'END_PERL';
package FOO;
use strict;
use warnings;
our $VERSION = 1.0;

$long_int = 12345678;  ## no critic
$oct_num  = 033;       ## no critic
my $noisy = '!';       ## no critic
my $empty = '';        ## no critic

$long_int = 12345678;
$oct_num  = 033;
my $noisy = '!';
my $empty = '';

#No final '1;'
END_PERL

is(
    critique(
        \$code,
        {-profile => $profile, -severity => 1, -theme => 'core'},
    ),
    5,
    'inline no-critic',
);

#-----------------------------------------------------------------------------

$code = <<'END_PERL';
package FOO;
use strict;
use warnings;
our $VERSION = 1.0;

$long_int = 12345678;  ## no critic
$oct_num  = 033;       ## no critic
my $noisy = '!';       ## no critic
my $empty = '';        ## no critic

## no critic
$long_int = 12345678;
$oct_num  = 033;
my $noisy = '!';
my $empty = '';

#No final '1;'
END_PERL

is(
    critique(
        \$code,
        {
            -profile  => $profile,
            -severity => 1,
            -theme    => 'core',
            -force    => 1,
        }
    ),
    9,
    'force option',
);

#-----------------------------------------------------------------------------

$code = <<'END_PERL';
package FOO;
use strict;
use warnings;
our $VERSION = 1.0;

for my $foo (@list) {
  ## no critic
  $long_int = 12345678;
  $oct_num  = 033;
}

my $noisy = '!'; ## no critic
my $empty = '';  ## no critic

1;
END_PERL

is(
    critique(
        \$code,
        {
            -profile  => $profile,
            -severity => 1,
            -theme    => 'core',
            -force    => 1,
        }
    ),
    4,
    'force option',
);

#-----------------------------------------------------------------------------

$code = <<'END_PERL';
package FOO;
use strict;
use warnings;
our $VERSION = 1.0;

for my $foo (@list) {
  ## no critic
  $long_int = 12345678;
  $oct_num  = 033;
}

## no critic
my $noisy = '!';
my $empty = '';

#No final '1;'
END_PERL

is(
    critique(
        \$code,
        {
            -profile  => $profile,
            -severity => 1,
            -theme    => 'core',
            -force    => 1,
        }
    ),
    5,
    'force option',
);

#-----------------------------------------------------------------------------
# Check that '## no critic' on the top of a block doesn't extend
# to all code within the block.  See RT bug #15295

$code = <<'END_PERL';
package FOO;
use strict;
use warnings;
our $VERSION = 1.0;

for ($i;$i++;$i<$j) { ## no critic
    my $long_int = 12345678;
    my $oct_num  = 033;
}

unless ( $condition1
         && $condition2 ) { ## no critic
    my $noisy = '!';
    my $empty = '';
}

1;
END_PERL

is(
    critique(
        \$code,
        {-profile  => $profile, -severity => 1, -theme => 'core'},
    ),
    4,
    'RT bug 15295',
);

#-----------------------------------------------------------------------------
# Check that '## no critic' on the top of a block doesn't extend
# to all code within the block.  See RT bug #15295

$code = <<'END_PERL';
package FOO;
use strict;
use warnings;
our $VERSION = 1.0;

for ($i; $i++; $i<$j) { ## no critic
    my $long_int = 12345678;
    my $oct_num  = 033;
}

#Between blocks now
$Global::Variable = "foo";  #Package var; double-quotes

unless ( $condition1
         && $condition2 ) { ## no critic
    my $noisy = '!';
    my $empty = '';
}

1;
END_PERL

is(
    critique(
        \$code,
        {-profile  => $profile, -severity => 1, -theme => 'core'}
    ),
    6,
    'RT bug 15295',
);

#-----------------------------------------------------------------------------

$code = <<'END_PERL';
package FOO;
use strict;
use warnings;
our $VERSION = 1.0;

sub grep {  ## no critic;
    return $foo;
}

sub grep { return $foo; } ## no critic
1;
END_PERL

is(
    critique(
        \$code,
        {-profile  => $profile, -severity => 1, -theme => 'core'},
    ),
    0,
    'no-critic on sub name',
);

#-----------------------------------------------------------------------------

$code = <<'END_PERL';
package FOO;
use strict;
use warnings;
our $VERSION = 1.0;

sub grep {  ## no critic;
   return undef; #Should find this!
}

1;
END_PERL

is(
    critique(
        \$code,
        {-profile  => $profile, -severity =>1, -theme => 'core'}
    ),
    1,
    'no-critic on sub name',
);

#-----------------------------------------------------------------------------

$code = <<'END_PERL';
package FOO;
use strict;
use warnings;
our $VERSION = 1.0;

## no critic (NoisyQuotes)
my $noisy = '!';
my $empty = '';
eval $string;

1;
END_PERL

is(
    critique(
        \$code,
        {-profile  => $profile, -severity => 1, -theme => 'core'}
    ),
    2,
    'per-policy no-critic',
);

#-----------------------------------------------------------------------------

$code = <<'END_PERL';
package FOO;
use strict;
use warnings;
our $VERSION = 1.0;

## no critic (ValuesAndExpressions)
my $noisy = '!';
my $empty = '';
eval $string;

1;
END_PERL

is(
    critique(
        \$code,
        {-profile  => $profile, -severity => 1, -theme => 'core'}
    ),
    1,
    'per-policy no-critic',
);

#-----------------------------------------------------------------------------

$code = <<'END_PERL';
package FOO;
use strict;
use warnings;
our $VERSION = 1.0;

## no critic (Noisy, Empty)
my $noisy = '!';
my $empty = '';
eval $string;

1;
END_PERL

is(
    critique(
        \$code,
        {-profile  => $profile, -severity => 1, -theme => 'core'}
    ),
    1,
    'per-policy no-critic',
);

#-----------------------------------------------------------------------------

$code = <<'END_PERL';
package FOO;
use strict;
use warnings;
our $VERSION = 1.0;

## no critic (NOISY, EMPTY, EVAL)
my $noisy = '!';
my $empty = '';
eval $string;

1;
END_PERL

is(
    critique(
        \$code,
        {-profile  => $profile, -severity => 1, -theme => 'core'}
    ),
    0,
    'per-policy no-critic',
);

#-----------------------------------------------------------------------------

$code = <<'END_PERL';
package FOO;
use strict;
use warnings;
our $VERSION = 1.0;

## no critic (Noisy, Empty, Eval)
my $noisy = '!';
my $empty = '';
eval $string;

## use critic
my $noisy = '!';
my $empty = '';
eval $string;

1;
END_PERL

is(
    critique(
        \$code,
        {-profile  => $profile, -severity => 1, -theme => 'core'}
    ),
    3,
    'per-policy no-critic',
);

#-----------------------------------------------------------------------------

$code = <<'END_PERL';
package FOO;
use strict;
use warnings;
our $VERSION = 1.0;

## no critic (Critic::Policy)
my $noisy = '!';
my $empty = '';
eval $string;

1;
END_PERL

is(
    critique(
        \$code,
        {-profile  => $profile, -severity => 1, -theme => 'core'}
    ),
    0,
    'per-policy no-critic',
);

#-----------------------------------------------------------------------------

$code = <<'END_PERL';
package FOO;
use strict;
use warnings;
our $VERSION = 1.0;

## no critic (Foo::Bar, Baz, Boom)
my $noisy = '!';
my $empty = '';
eval $string;

1;
END_PERL

is(
    critique(
        \$code,
        {-profile  => $profile, -severity => 1, -theme => 'core'}
    ),
    3,
    'per-policy no-critic',
);

#-----------------------------------------------------------------------------

$code = <<'END_PERL';
package FOO;
use strict;
use warnings;
our $VERSION = 1.0;

## no critic (Noisy)
my $noisy = '!';     #Should not find this
my $empty = '';      #Should find this

sub foo {

   ## no critic (Empty)
   my $nosiy = '!';  #Should not find this
   my $empty = '';   #Should not find this
   ## use critic;

   return 1;
}

my $nosiy = '!';  #Should not find this
my $empty = '';   #Should find this

1;
END_PERL

is(
    critique(
        \$code,
        {-profile  => $profile, -severity => 1, -theme => 'core'}
    ),
    2,
    'per-policy no-critic',
);

#-----------------------------------------------------------------------------
$code = <<'END_PERL';
package FOO;

use strict;
use warnings;
our $VERSION = 1.0;

# with parentheses
my $noisy = '!';           ##no critic (NoisyQuotes)
barf() unless $$ eq '';    ##no critic (Postfix,Empty,Punctuation)
barf() unless $$ eq '';    ##no critic (Postfix , Empty , Punctuation)
barf() unless $$ eq '';    ##no critic (Postfix Empty Punctuation)

# qw() style
my $noisy = '!';           ##no critic qw(NoisyQuotes);
barf() unless $$ eq '';    ##no critic qw(Postfix,Empty,Punctuation)
barf() unless $$ eq '';    ##no critic qw(Postfix , Empty , Punctuation)
barf() unless $$ eq '';    ##no critic qw(Postfix Empty Punctuation)

# no parentheses
my $noisy = '!';           ##no critic NoisyQuotes;
barf() unless $$ eq '';    ##no critic Postfix,Empty,Punctuation;
barf() unless $$ eq '';    ##no critic Postfix , Empty , Punctuation;
barf() unless $$ eq '';    ##no critic Postfix Empty Punctuation;

1;
END_PERL

is(
    critique(
        \$code,
        {-profile => $profile, -severity => 1, -theme => 'core'},
    ),
    0,
    'no critic: syntaxes',
);

#-----------------------------------------------------------------------------
# Most policies apply to a particular type of PPI::Element and usually
# only return one Violation at a time.  But the next three cases
# involve policies that apply to the whole document and can return
# multiple violations at a time.  These tests make sure that the 'no
# critic' pragmas are effective with those Policies
#-----------------------------------------------------------------------------

$code = <<'END_PERL';
package FOO;

#Code before 'use strict'
my $foo = 'baz';  ## no critic
my $bar = 42;     # Should find this

use strict;
use warnings;
our $VERSION = 1.0;

1;
END_PERL

is(
    critique(
        \$code,
        {-profile  => $profile, -severity => 5, -theme => 'core'},
    ),
    1,
    'no critic & RequireUseStrict',
);

#-----------------------------------------------------------------------------

$code = <<'END_PERL';
package FOO;
use strict;

#Code before 'use warnings'
my $foo = 'baz';  ## no critic
my $bar = 42;  # Should find this

use warnings;
our $VERSION = 1.0;

1;
END_PERL

is(
    critique(
        \$code,
        {-profile  => $profile, -severity => 4, -theme => 'core'},
    ),
    1,
    'no critic & RequireUseWarnings',
);

#-----------------------------------------------------------------------------

$code = <<'END_PERL';
use strict;      ##no critic
use warnings;    #should find this
my $bar = 42;    #this one will be squelched

package FOO;

our $VERSION = 1.0;

1;
END_PERL

is(
    critique(
        \$code,
        {-profile  => $profile, -severity => 4, -theme => 'core'},
    ),
    1,
    'no critic & RequireExplicitPackage',
);

#-----------------------------------------------------------------------------

# ensure we run true if this test is loaded by
# t/03_pragmas.t_without_optional_dependencies.t
1;

##############################################################################
# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
