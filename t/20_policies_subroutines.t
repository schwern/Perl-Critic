##################################################################
#     $URL$
#    $Date$
#   $Author$
# $Revision$
##################################################################

use strict;
use warnings;
use Test::More tests => 22;
use Perl::Critic::Config;
use Perl::Critic;

# common P::C testing tools
use lib qw(t/tlib);
use PerlCriticTestUtils qw(pcritique);
PerlCriticTestUtils::block_perlcriticrc();

my $code ;
my $policy;
my %config;

#----------------------------------------------------------------

$code = <<'END_PERL';
sub test_sub1 {
	$foo = shift;
	return undef;
}

sub test_sub2 {
	shift || return undef;
}

sub test_sub3 {
	return undef if $bar;
}

END_PERL

$policy = 'Subroutines::ProhibitExplicitReturnUndef';
is( pcritique($policy, \$code), 3, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
sub test_sub1 {
	$foo = shift;
	return;
}

sub test_sub2 {
	shift || return;
}

sub test_sub3 {
	return if $bar;
}

END_PERL

$policy = 'Subroutines::ProhibitExplicitReturnUndef';
is( pcritique($policy, \$code), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
sub my_sub1 ($@) {}
sub my_sub2 (@@) {}
END_PERL

$policy = 'Subroutines::ProhibitSubroutinePrototypes';
is( pcritique($policy, \$code), 2, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
sub my_sub1 {}
sub my_sub1 {}
END_PERL

$policy = 'Subroutines::ProhibitSubroutinePrototypes';
is( pcritique($policy, \$code), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
sub open {}
sub map {}
sub eval {}
END_PERL

$policy = 'Subroutines::ProhibitBuiltinHomonyms';
is( pcritique($policy, \$code), 3, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
sub my_open {}
sub my_map {}
sub eval2 {}
END_PERL

$policy = 'Subroutines::ProhibitBuiltinHomonyms';
is( pcritique($policy, \$code), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
sub import {}
END_PERL

$policy = 'Subroutines::ProhibitBuiltinHomonyms';
is( pcritique($policy, \$code), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
sub foo { }
END_PERL

$policy = 'Subroutines::RequireFinalReturn';
is( pcritique($policy, \$code), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
sub foo { return; }
END_PERL

$policy = 'Subroutines::RequireFinalReturn';
is( pcritique($policy, \$code), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
sub foo { return {some => [qw(complicated data)], q{ } => /structure/}; }
END_PERL

$policy = 'Subroutines::RequireFinalReturn';
is( pcritique($policy, \$code), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
sub foo { if (1) { return; } else { return; } }
END_PERL

$policy = 'Subroutines::RequireFinalReturn';
is( pcritique($policy, \$code), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
sub foo { if (1) { return; } elsif (2) { return; } else { return; } }
END_PERL

$policy = 'Subroutines::RequireFinalReturn';
is( pcritique($policy, \$code), 0, $policy);

#----------------------------------------------------------------

TODO:{
local $TODO = 'we are not yet detecting ternaries';

$code = <<'END_PERL';
sub foo { 1 ? return : 2 ? return : return; }
END_PERL

#TODO blocks don't seem to work properly with the Test::Harness
#that I have at work. So for now, I'm just going to disable these
#tests.

#$policy = 'Subroutines::RequireFinalReturn';
#is( pcritique($policy, \$code), 0, $policy);
1;

}

#----------------------------------------------------------------

$code = <<'END_PERL';
sub foo { return 1 ? 1 : 2 ? 2 : 3; }
END_PERL

$policy = 'Subroutines::RequireFinalReturn';
is( pcritique($policy, \$code), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
sub foo { 'Club sandwich'; }
END_PERL

$policy = 'Subroutines::RequireFinalReturn';
is( pcritique($policy, \$code), 1, $policy);

#----------------------------------------------------------------

# This one IS valid to a human or an optimizer, but it's too rare and
# too hard to detect so we disallow it

$code = <<'END_PERL';
sub foo { while (1==1) { return; } }
END_PERL

$policy = 'Subroutines::RequireFinalReturn';
is( pcritique($policy, \$code), 1, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
sub foo { if (1) { $foo = 'bar'; } else { return; } }
END_PERL

$policy = 'Subroutines::RequireFinalReturn';
is( pcritique($policy, \$code), 1, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
&function_call();
&my_package::function_call();
&function_call( $args );
&my_package::function_call( %args );
&function_call( &other_call( @foo ), @bar );
&::function_call();
END_PERL

$policy = 'Subroutines::ProhibitAmpersandSigils';
is( pcritique($policy, \$code), 7, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
function_call();
my_package::function_call();
function_call( $args );
my_package::function_call( %args );
function_call( other_call( @foo ), @bar );
\&my_package::function_call;
\&function_call;
END_PERL

$policy = 'Subroutines::ProhibitAmpersandSigils';
is( pcritique($policy, \$code), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
sub teest_sub {
    if ( $foo && $bar || $baz ) {
        open my $fh, '<', $file or die $!;
    }
    elsif ( $blah >>= some_function() ) {
        return if $barf;
    }
    else {
        $results = $condition ? 1 : 0;
    }
    croak unless $result;
}
END_PERL

%config = ( max_mccabe => 9 );
$policy = 'Subroutines::ProhibitExcessComplexity';
is( pcritique($policy, \$code, \%config), 1, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
sub teest_sub {
    if ( $foo && $bar || $baz ) {
        open my $fh, '<', $file or die $!;
    }
    elsif ( $blah >>= some_function() ) {
        return if $barf;
    }
    else {
        $results = $condition ? 1 : 0;
    }
    croak unless $result;
}
END_PERL

$policy = 'Subroutines::ProhibitExcessComplexity';
is( pcritique($policy, \$code), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
Other::Package::_foo();
Other::Package->_bar();
Other::Package::_foo;
Other::Package->_bar;
$self->Other::Package::_baz();
END_PERL

$policy = 'Subroutines::ProtectPrivateSubs';
is( pcritique($policy, \$code), 5, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';

# This one should be illegal, but it is too hard to distinguish from
# the next one, which is legal
$pkg->_foo();

$self->_bar();
$self->SUPER::_foo();
END_PERL

$policy = 'Subroutines::ProtectPrivateSubs';
is( pcritique($policy, \$code), 0, $policy);

