#######################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
# ex: set ts=8 sts=4 sw=4 expandtab
########################################################################

package Perl::Critic::Config;

use strict;
use warnings;
use Carp qw(carp confess);
use English qw(-no_match_vars);
use File::Spec::Unix qw();
use List::MoreUtils qw(any none);
use Scalar::Util qw(blessed);
use Perl::Critic::PolicyFactory;
use Perl::Critic::UserProfile;
use Perl::Critic::Utils;

our $VERSION = 0.21;

# Globals.  Ick!
my $NAMESPACE = $EMPTY;
my $DEFAULT_NAMESPACE = 'Perl::Critic::Policy';
my @SITE_POLICIES = ();

#-----------------------------------------------------------------------------

sub import {

    my ( $class, %args ) = @_;
    my $test_mode = $args{-test};
    $NAMESPACE    = $args{-namespace} || $DEFAULT_NAMESPACE;


    eval {
        require Module::Pluggable;
        Module::Pluggable->import(search_path => $NAMESPACE,
                                  require => 1, inner => 0);
        @SITE_POLICIES = plugins(); #Exported by Module::Pluggable
    };

    if ( $EVAL_ERROR ) {
        confess qq{Can't load Policies from namespace '$NAMESPACE': $EVAL_ERROR};
    }
    elsif ( ! @SITE_POLICIES ) {
        carp qq{No Policies found in namespace '$NAMESPACE'};
    }

    # In test mode, only load native policies, not third-party ones
    if ( $test_mode && any {m/\b blib \b/xms} @INC ) {
        @SITE_POLICIES = _modules_from_blib( @SITE_POLICIES );
    }

    return 1;
}

#---------------------------------------------------------------------------
# Some static helper subs

sub _modules_from_blib {
    my (@modules) = @_;
    return grep { _was_loaded_from_blib( _module2path($_) ) } @modules;
}

sub _module2path {
    my $module = shift || return;
    return File::Spec::Unix->catdir(split m/::/xms, $module) . '.pm';
}

sub _was_loaded_from_blib {
    my $path = shift || return;
    my $full_path = $INC{$path};
    return $full_path && $full_path =~ m/\b blib \b/xms;
}

#-----------------------------------------------------------------------------
# Constructor

sub new {

    my ( $class, %args ) = @_;
    my $self = bless {}, $class;
    $self->_init($NAMESPACE, %args);
    return $self;
}

#-----------------------------------------------------------------------------

sub _init {

    my ( $self, $ns, %args ) = @_;
    my $p = $args{-profile};

    my $profile = Perl::Critic::UserProfile->new( -profile => $p, -namespace => $ns );
    $self->{_exclude}  = $args{-exclude}  || $profile->defaults->exclude();
    $self->{_force}    = $args{-force}    || $profile->defaults->force();
    $self->{_include}  = $args{-include}  || $profile->defaults->include();
    $self->{_nocolor}  = $args{-nocolor}  || $profile->defaults->nocolor();
    $self->{_only}     = $args{-only}     || $profile->defaults->only();
    $self->{_severity} = $args{-severity} || $profile->defaults->severity();
    $self->{_theme}    = $args{-theme}    || $profile->defaults->theme();
    $self->{_verbose}  = $args{-verbose}  || $profile->defaults->verbose();
    $self->{_profile}  = $profile;
    $self->{_policies} = [];

    # "NONE" means don't load any policies
    return $self if defined $p and $p eq 'NONE';

    $self->_load_policies( @SITE_POLICIES );
    return $self;
}

#-----------------------------------------------------------------------------

sub add_policy {

    my ( $self, %args ) = @_;
    my $profile = $self->{_profile};
    my $policy  = $args{-policy} || return;
    my $params  = $args{-params} || $args{-config} || $profile->policy_params( $policy );

    eval {
        my $policy_name = policy_long_name( $policy, $NAMESPACE );
        my $policy_obj  = $policy_name->new( %{ $params } );
        push @{ $self->{_policies} }, $policy_obj;
    };


    if ($EVAL_ERROR) {
        carp qq{Failed to create policy '$policy': $EVAL_ERROR};
        return;  #Not fatal!
    }


    return $self;
}

#-----------------------------------------------------------------------------

sub _load_policies {

    my ( $self, @policy_names ) = @_;

    my $factory = Perl::Critic::PolicyFactory->new( -profile  => $self->{_profile},
                                                    -policies => \@policy_names );

    for my $policy ( $factory->policies() ) {

        my $load_me = $TRUE; #Assume policy should be loaded

        ##no critic (ProhibitPostfixControls)
        $load_me = $FALSE if $self->_policy_is_disabled( $policy );
        $load_me = $FALSE if $self->_policy_is_unimportant( $policy );
        $load_me = $FALSE if not $self->_policy_is_thematic( $policy );
        $load_me = $TRUE  if $self->_policy_is_included( $policy );
        $load_me = $FALSE if $self->_policy_is_excluded( $policy );

        next if not $load_me;
        push @{ $self->{_policies} }, $policy;
    }

    return $self;
}

#-----------------------------------------------------------------------------

sub _policy_is_disabled {
    my ($self, $policy) = @_;
    my $profile = $self->{_profile};
    return $profile->policy_is_disabled( $policy );
}

#-----------------------------------------------------------------------------

sub _policy_is_ensabled {
    my ($self, $policy) = @_;
    my $profile = $self->{_profile};
    return $profile->policy_is_enabled( $policy );
}

#-----------------------------------------------------------------------------

sub _policy_is_thematic {
    my ($self, $policy) = @_;
    my $theme_manager = $self->{_theme_manager};
    return 1 if not $theme_manager;
    return $theme_manager->is_thematic( $policy );
}

#-----------------------------------------------------------------------------

sub _policy_is_unimportant {
    my ($self, $policy) = @_;
    my $policy_severity = $policy->get_severity();
    my $min_severity    = $self->{_severity};
    return $policy_severity < $min_severity;
}

#-----------------------------------------------------------------------------

sub _policy_is_included {
    my ($self, $policy) = @_;
    my $policy_long_name = ref $policy;
    my @inclusions  = $self->include();
    return any { $policy_long_name =~ m/$_/imx } @inclusions;
}

#-----------------------------------------------------------------------------

sub _policy_is_excluded {
    my ($self, $policy) = @_;
    my $policy_long_name = ref $policy;
    my @exclusions  = $self->exclude();
    return any { $policy_long_name =~ m/$_/imx } @exclusions;
}

#------------------------------------------------------------------------
# Begin ACCESSSOR methods

sub policies {
    my $self = shift;
    return @{ $self->{_policies} };
}

#----------------------------------------------------------------------------

sub exclude {
    my $self = shift;
    return @{ $self->{_exclude} };
}

#----------------------------------------------------------------------------

sub force {
    my $self = shift;
    return $self->{_force};
}

#----------------------------------------------------------------------------

sub include {
    my $self = shift;
    return @{ $self->{_include} };
}

#----------------------------------------------------------------------------

sub nocolor {
    my $self = shift;
    return $self->{_nocolor};
}

#----------------------------------------------------------------------------

sub only {
    my $self = shift;
    return $self->{_only};
}

#----------------------------------------------------------------------------

sub theme {
    my $self = shift;
    return $self->{_theme};
}

#----------------------------------------------------------------------------

sub top {
    my $self = shift;
    return $self->{_top};
}

#----------------------------------------------------------------------------

sub verbose {
    my $self = shift;
    return $self->{_verbose};
}

#----------------------------------------------------------------------------

sub site_policies {
    return @SITE_POLICIES;
}

# This list should be in alphabetic order but it's no longer critical
sub native_policies {
    return qw(
      Perl::Critic::Policy::BuiltinFunctions::ProhibitLvalueSubstr
      Perl::Critic::Policy::BuiltinFunctions::ProhibitReverseSortBlock
      Perl::Critic::Policy::BuiltinFunctions::ProhibitSleepViaSelect
      Perl::Critic::Policy::BuiltinFunctions::ProhibitStringyEval
      Perl::Critic::Policy::BuiltinFunctions::ProhibitStringySplit
      Perl::Critic::Policy::BuiltinFunctions::ProhibitUniversalCan
      Perl::Critic::Policy::BuiltinFunctions::ProhibitUniversalIsa
      Perl::Critic::Policy::BuiltinFunctions::RequireBlockGrep
      Perl::Critic::Policy::BuiltinFunctions::RequireBlockMap
      Perl::Critic::Policy::BuiltinFunctions::RequireGlobFunction
      Perl::Critic::Policy::BuiltinFunctions::RequireSimpleSortBlock
      Perl::Critic::Policy::ClassHierarchies::ProhibitAutoloading
      Perl::Critic::Policy::ClassHierarchies::ProhibitExplicitISA
      Perl::Critic::Policy::ClassHierarchies::ProhibitOneArgBless
      Perl::Critic::Policy::CodeLayout::ProhibitHardTabs
      Perl::Critic::Policy::CodeLayout::ProhibitParensWithBuiltins
      Perl::Critic::Policy::CodeLayout::ProhibitQuotedWordLists
      Perl::Critic::Policy::CodeLayout::RequireConsistentNewlines
      Perl::Critic::Policy::CodeLayout::RequireTidyCode
      Perl::Critic::Policy::CodeLayout::RequireTrailingCommas
      Perl::Critic::Policy::ControlStructures::ProhibitCStyleForLoops
      Perl::Critic::Policy::ControlStructures::ProhibitCascadingIfElse
      Perl::Critic::Policy::ControlStructures::ProhibitDeepNests
      Perl::Critic::Policy::ControlStructures::ProhibitPostfixControls
      Perl::Critic::Policy::ControlStructures::ProhibitUnlessBlocks
      Perl::Critic::Policy::ControlStructures::ProhibitUnreachableCode
      Perl::Critic::Policy::ControlStructures::ProhibitUntilBlocks
      Perl::Critic::Policy::Documentation::RequirePodAtEnd
      Perl::Critic::Policy::Documentation::RequirePodSections
      Perl::Critic::Policy::ErrorHandling::RequireCarping
      Perl::Critic::Policy::InputOutput::ProhibitBacktickOperators
      Perl::Critic::Policy::InputOutput::ProhibitBarewordFileHandles
      Perl::Critic::Policy::InputOutput::ProhibitInteractiveTest
      Perl::Critic::Policy::InputOutput::ProhibitOneArgSelect
      Perl::Critic::Policy::InputOutput::ProhibitReadlineInForLoop
      Perl::Critic::Policy::InputOutput::ProhibitTwoArgOpen
      Perl::Critic::Policy::InputOutput::RequireBracedFileHandleWithPrint
      Perl::Critic::Policy::Miscellanea::ProhibitFormats
      Perl::Critic::Policy::Miscellanea::ProhibitTies
      Perl::Critic::Policy::Miscellanea::RequireRcsKeywords
      Perl::Critic::Policy::Modules::ProhibitAutomaticExportation
      Perl::Critic::Policy::Modules::ProhibitEvilModules
      Perl::Critic::Policy::Modules::ProhibitMultiplePackages
      Perl::Critic::Policy::Modules::RequireBarewordIncludes
      Perl::Critic::Policy::Modules::RequireEndWithOne
      Perl::Critic::Policy::Modules::RequireExplicitPackage
      Perl::Critic::Policy::Modules::RequireFilenameMatchesPackage
      Perl::Critic::Policy::Modules::RequireVersionVar
      Perl::Critic::Policy::NamingConventions::ProhibitAmbiguousNames
      Perl::Critic::Policy::NamingConventions::ProhibitMixedCaseSubs
      Perl::Critic::Policy::NamingConventions::ProhibitMixedCaseVars
      Perl::Critic::Policy::References::ProhibitDoubleSigils
      Perl::Critic::Policy::RegularExpressions::ProhibitCaptureWithoutTest
      Perl::Critic::Policy::RegularExpressions::RequireExtendedFormatting
      Perl::Critic::Policy::RegularExpressions::RequireLineBoundaryMatching
      Perl::Critic::Policy::Subroutines::ProhibitAmpersandSigils
      Perl::Critic::Policy::Subroutines::ProhibitBuiltinHomonyms
      Perl::Critic::Policy::Subroutines::ProhibitExcessComplexity
      Perl::Critic::Policy::Subroutines::ProhibitExplicitReturnUndef
      Perl::Critic::Policy::Subroutines::ProhibitSubroutinePrototypes
      Perl::Critic::Policy::Subroutines::ProtectPrivateSubs
      Perl::Critic::Policy::Subroutines::RequireFinalReturn
      Perl::Critic::Policy::TestingAndDebugging::ProhibitNoStrict
      Perl::Critic::Policy::TestingAndDebugging::ProhibitNoWarnings
      Perl::Critic::Policy::TestingAndDebugging::RequireTestLabels
      Perl::Critic::Policy::TestingAndDebugging::RequireUseStrict
      Perl::Critic::Policy::TestingAndDebugging::RequireUseWarnings
      Perl::Critic::Policy::ValuesAndExpressions::ProhibitConstantPragma
      Perl::Critic::Policy::ValuesAndExpressions::ProhibitEmptyQuotes
      Perl::Critic::Policy::ValuesAndExpressions::ProhibitEscapedCharacters
      Perl::Critic::Policy::ValuesAndExpressions::ProhibitInterpolationOfLiterals
      Perl::Critic::Policy::ValuesAndExpressions::ProhibitLeadingZeros
      Perl::Critic::Policy::ValuesAndExpressions::ProhibitMixedBooleanOperators
      Perl::Critic::Policy::ValuesAndExpressions::ProhibitNoisyQuotes
      Perl::Critic::Policy::ValuesAndExpressions::ProhibitVersionStrings
      Perl::Critic::Policy::ValuesAndExpressions::RequireInterpolationOfMetachars
      Perl::Critic::Policy::ValuesAndExpressions::RequireNumberSeparators
      Perl::Critic::Policy::ValuesAndExpressions::RequireQuotedHeredocTerminator
      Perl::Critic::Policy::ValuesAndExpressions::RequireUpperCaseHeredocTerminator
      Perl::Critic::Policy::Variables::ProhibitConditionalDeclarations
      Perl::Critic::Policy::Variables::ProhibitLocalVars
      Perl::Critic::Policy::Variables::ProhibitMatchVars
      Perl::Critic::Policy::Variables::ProhibitPackageVars
      Perl::Critic::Policy::Variables::ProhibitPunctuationVars
      Perl::Critic::Policy::Variables::ProtectPrivateVars
      Perl::Critic::Policy::Variables::RequireInitializationForLocalVars
      Perl::Critic::Policy::Variables::RequireLexicalLoopIterators
      Perl::Critic::Policy::Variables::RequireNegativeIndices
    );
}

1;

#----------------------------------------------------------------------------

__END__

=pod

=head1 NAME

Perl::Critic::Config - Find and load Perl::Critic user-preferences

=head1 DESCRIPTION

Perl::Critic::Config takes care of finding and processing
user-preferences for L<Perl::Critic>.  The Config object defines which
Policy modules will be loaded into the Perl::Critic engine and how
they should be configured.  You should never really need to
instantiate Perl::Critic::Config directly because the Perl::Critic
constructor will do it for you.

=head1 CONSTRUCTOR

=over 8

=item C<< new( [ -profile => $FILE, -severity => $N, -include => \@PATTERNS, -exclude => \@PATTERNS ] ) >>

Returns a reference to a new Perl::Critic::Config object, which is
basically just a blessed hash of configuration parameters.  There
aren't any special methods for getting and setting individual values,
so just treat it like an ordinary hash.  All arguments are optional
key-value pairs as follows:

B<-profile> is a path to a configuration file. If C<$FILE> is not
defined, Perl::Critic::Config attempts to find a F<.perlcriticrc>
configuration file in the current directory, and then in your home
directory.  Alternatively, you can set the C<PERLCRITIC> environment
variable to point to a file in another location.  If a configuration
file can't be found, or if C<$FILE> is an empty string, then all
Policies will be loaded with their default configuration.  See
L<"CONFIGURATION"> for more information.

B<-severity> is the minimum severity level.  Only Policy modules that
have a severity greater than C<$N> will be loaded into this Config.
Severity values are integers ranging from 1 (least severe) to 5 (most
severe).  The default is 5.  For a given C<-profile>, decreasing the
C<-severity> will usually result in more Policy violations.  Users can
redefine the severity level for any Policy in their F<.perlcriticrc>
file.  See L<"CONFIGURATION"> for more information.

B<-include> is a reference to a list of string C<@PATTERNS>.  Policies
that match at least one C<m/$PATTERN/imx> will be loaded into this
Config, irrespective of the severity settings.  You can use it in
conjunction with the C<-exclude> option.  Note that C<-exclude> takes
precedence over C<-include> when a Policy matches both patterns.

B<-exclude> is a reference to a list of string C<@PATTERNS>.  Polices
that match at least one C<m/$PATTERN/imx> will not be loaded into this
Config, irrespective of the severity settings.  You can use it in
conjunction with the C<-include> option.  Note that C<-exclude> takes
precedence over C<-include> when a Policy matches both patterns.

=back

=head1 METHODS

=over 8

=item C<< add_policy( -policy => $policy_name, -config => \%config_hash ) >>

Creates a Policy object and loads it into this Critic.  If the object
cannot be instantiated, it will throw a warning and return a false
value.  Otherwise, it returns a reference to this Critic.

B<-policy> is the name of a L<Perl::Critic::Policy> subclass
module.  The C<'Perl::Critic::Policy'> portion of the name can be
omitted for brevity.  This argument is required.

B<-config> is an optional reference to a hash of Policy configuration
parameters.  Note that this is B<not> the same thing as a
L<Perl::Critic::Config> object. The contents of this hash reference
will be passed into to the constructor of the Policy module.  See the
documentation in the relevant Policy module for a description of the
arguments it supports.

=item C< policies() >

Returns a list containing references to all the Policy objects that
have been loaded into this Config.  Objects will be in the order that
they were loaded.

=item C< exclude() >

=item C< force() >

=item C< include() >

=item C< nocolor() >

=item C< only() >

=item C< severity() >

=item C< theme() >

=item C< top() >

=item C< verbose() >

=back

=head1 SUBROUTINES

Perl::Critic::Config has a few static subroutines that are used
internally, but may be useful to you in some way.

=over 8

=item C<site_policies()>

Returns a list of all the Policy modules that are currently installed
in the Perl::Critic:Policy namespace.  These will include modules that
are distributed with Perl::Critic plus any third-party modules that
have been installed.

=item C<native_policies()>

Returns a list of all the Policy modules that have been distributed
with Perl::Critic.  Does not include any third-party modules.

=back

=head1 ADVANCED USAGE

All the Policy modules that ship with Perl::Critic are in the
C<"Perl::Critic::Policy"> namespace.  To load modules from an alternate
namespace, import Perl::Critic::Config using the C<-namespace> option
like this:

  use Perl::Critic::Config -namespace => 'Foo::Bar'; #Loads from Foo::Bar::*

At the moment, only one alternate namespace may be specified.  Unless
Policy module names are fully qualified, Perl::Critic::Config assumes
that all Policies are in the specified namespace.  So if you want to
use Policies from multiple namespaces, you will need to use the full
module name in your F<.perlcriticrc> file.

=head1 CONFIGURATION

The default configuration file is called F<.perlcriticrc>.
Perl::Critic::Config will look for this file in the current directory
first, and then in your home directory.  Alternatively, you can set
the PERLCRITIC environment variable to explicitly point to a different
file in another location.  If none of these files exist, and the
C<-profile> option is not given to the constructor, then all the
modules that are found in the Perl::Critic::Policy namespace will be
loaded with their default configuration.

The format of the configuration file is a series of named sections
that contain key-value pairs separated by '='. Comments should
start with '#' and can be placed on a separate line or after the
name-value pairs if you desire.  The general recipe is a series of
blocks like this:

    [Perl::Critic::Policy::Category::PolicyName]
    severity = 1
    arg1 = value1
    arg2 = value2

C<Perl::Critic::Policy::Category::PolicyName> is the full name of a
module that implements the policy.  The Policy modules distributed
with Perl::Critic have been grouped into categories according to the
table of contents in Damian Conway's book B<Perl Best Practices>. For
brevity, you can omit the C<'Perl::Critic::Policy'> part of the
module name.

C<severity> is the level of importance you wish to assign to the
Policy.  All Policy modules are defined with a default severity value
ranging from 1 (least severe) to 5 (most severe).  However, you may
disagree with the default severity and choose to give it a higher or
lower severity, based on your own coding philosophy.

The remaining key-value pairs are configuration parameters that will
be passed into the constructor of that Policy.  The constructors for
most Policy modules do not support arguments, and those that do should
have reasonable defaults.  See the documentation on the appropriate
Policy module for more details.

Instead of redefining the severity for a given Policy, you can
completely disable a Policy by prepending a '-' to the name of the
module in your configuration file.  In this manner, the Policy will
never be loaded, regardless of the C<-severity> given to the
Perl::Critic::Config constructor.

A simple configuration might look like this:

    #--------------------------------------------------------------
    # I think these are really important, so always load them

    [TestingAndDebugging::RequireUseStrict]
    severity = 5

    [TestingAndDebugging::RequireUseWarnings]
    severity = 5

    #--------------------------------------------------------------
    # I think these are less important, so only load when asked

    [Variables::ProhibitPackageVars]
    severity = 2

    [ControlStructures::ProhibitPostfixControls]
    allow = if unless  #A policy-specific configuration
    severity = 2

    #--------------------------------------------------------------
    # I do not agree with these at all, so never load them

    [-NamingConventions::ProhibitMixedCaseVars]
    [-NamingConventions::ProhibitMixedCaseSubs]

    #--------------------------------------------------------------
    # For all other Policies, I accept the default severity,
    # so no additional configuration is required for them.

A few sample configuration files are included in this distribution
under the F<t/samples> directory. The F<perlcriticrc.none> file
demonstrates how to disable Policy modules.  The
F<perlcriticrc.levels> file demonstrates how to redefine the severity
level for any given Policy module.  The F<perlcriticrc.pbp> file
configures Perl::Critic to load only Policies described in Damian
Conway's book "Perl Best Practices."

=head1 AUTHOR

Jeffrey Ryan Thalhammer <thaljef@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2005-2006 Jeffrey Ryan Thalhammer.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  The full text of this license
can be found in the LICENSE file included with this module.

=cut
