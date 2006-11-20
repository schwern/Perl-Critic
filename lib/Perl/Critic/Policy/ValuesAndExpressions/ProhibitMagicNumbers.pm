##############################################################################
#     $URL$
#    $Date$
#   $Author$
# $Revision$
##############################################################################

package Perl::Critic::Policy::ValuesAndExpressions::ProhibitMagicNumbers;

use strict;
use warnings;

# force $PPI::VERSION to be initialized so that the BEGIN block below works.
use PPI;
use List::MoreUtils qw{ any };

use Perl::Critic::Utils;
use base 'Perl::Critic::Policy';

our $VERSION = 0.22;

#----------------------------------------------------------------------------

my $DESC = q{Numeric literals make code less maintainable};
my $USE_READONLY_OR_CONSTANT =
    ' Use the Readonly module or the "constant" pragma instead';
my $TYPE_NOT_ALLOWED_SUFFIX = ") are not allowed.$USE_READONLY_OR_CONSTANT";

#----------------------------------------------------------------------------

sub default_severity { return $SEVERITY_LOW        }
sub default_themes   { return qw( readability )    }
sub applies_to       { return 'PPI::Token::Number' }

#----------------------------------------------------------------------------

sub new {
    my ( $class, %config ) = @_;
    my $self = bless {}, $class;

    #Set config, if defined
    my ($all_integers_allowed, $allowed_values) =
        _determine_allowed_values(%config);

    my $allowed_string  = ' is not one of the allowed literal values (';
    if ($all_integers_allowed) {
        $allowed_string .= 'all integers';

        if ( %{$allowed_values} ) {
            $allowed_string .= ', ';
        } # end if
    } # end if
    $allowed_string .=
          ( join ', ', sort { $a <=> $b } keys %{$allowed_values} )
        . ').'
        . $USE_READONLY_OR_CONSTANT;

    $self->{_allowed_values}        = $allowed_values;
    $self->{_all_integers_allowed}  = $all_integers_allowed;
    $self->{_allowed_string}        = $allowed_string;
    $self->{_checked_types}         = _determine_checked_types(%config);

    return $self;
} # end new()

sub _determine_allowed_values {
    my %config = @_;

    my @allowed_values;
    my $all_integers_allowed;
    if ( defined $config{allowed_values} ) {
        my @allowed_values_strings =
            grep {$_} split m/\s+/xms, $config{allowed_values};

        $all_integers_allowed =
            any { 'all_integers' eq $_ } @allowed_values_strings;

        if ($all_integers_allowed) {
            foreach my $allowed_value_string (@allowed_values_strings) {
                if (
                        'all_integers' ne $allowed_value_string
                    and int($allowed_value_string) != $allowed_value_string
                ) {
                    push @allowed_values, ($allowed_value_string + 0);
                } # end if
            } # end foreach
        } else {
            @allowed_values = map { $_ + 0 } @allowed_values_strings;
        } # end if
    } else {
        @allowed_values = ( 2 );
    } # end if

    if (not $all_integers_allowed) {
        push @allowed_values, 0, 1;
    } # end if
    my %allowed_values = hashify(@allowed_values);

    return ($all_integers_allowed, \%allowed_values);
} # end _determine_allowed_values()

sub _determine_checked_types {
    my %config = @_;

    my %checked_types = (
        'PPI::Token::Number::Binary'  => 'Binary literals ('         ,
        'PPI::Token::Number::Float'   => 'Floating-point literals (' ,
        'PPI::Token::Number::Exp'     => 'Exponential literals ('    ,
        'PPI::Token::Number::Hex'     => 'Hexadecimal literals ('    ,
        'PPI::Token::Number::Octal'   => 'Octal literals ('          ,
        'PPI::Token::Number::Version' => 'Version literals ('        ,
    );

    if ( defined $config{allowed_types} ) {
        foreach my $allowed_type (
            grep {$_} split m/\s+/xms, $config{allowed_types}
        ) {
            delete $checked_types{ "PPI::Token::Number::$allowed_type" };

            if ($allowed_type eq 'Exp') {
                # because an Exp isa(Float).
                delete $checked_types{ 'PPI::Token::Number::Float' };
            } # end if
        } # end foreach
    } else {
        delete $checked_types{ 'PPI::Token::Number::Float' };
    } # end if

    return \%checked_types;
} # end _determine_checked_types()

sub _real_violates {
    my ( $self, $elem, undef ) = @_;

    return if _element_is_in_an_include_readonly_or_version_statement($elem);

    my $literal = $elem->literal();
    if (
            defined $literal
        and not (
                    $self->{_all_integers_allowed}
                and int($literal) == $literal
        )
        and not defined $self->{_allowed_values}{ $literal }
    ) {
        return
            $self->violation(
                $DESC,
                $elem->content() . $self->{_allowed_string},
                $elem,
            );
    } # end if

    my ($number_type, $type_string);
    while (
          ( $number_type, $type_string )
        = ( each %{ $self->{_checked_types} } )
    ) {
        if ( $elem->isa( $number_type ) ) {
            return
                $self->violation(
                    $DESC,
                    $type_string . $elem->content() . $TYPE_NOT_ALLOWED_SUFFIX,
                    $elem,
                );
        } # end if
    } # end foreach

    return;
} # end _real_violates()

sub _pre119_violates {
    return;
} # end _pre119_violates()


BEGIN {
    if ($PPI::VERSION le '1.118') {
        *violates = *_pre119_violates{CODE};
    } else {
        *violates = *_real_violates{CODE};
    } # end if
} # end BEGIN


sub _element_is_in_an_include_readonly_or_version_statement {
    my $elem = shift;

    my $parent = $elem->parent();
    while ($parent) {
        if ($parent->isa('PPI::Statement')) {
            return 1 if $parent->isa('PPI::Statement::Include');

            if ( $parent->isa('PPI::Statement::Variable') ) {
                if ( $parent->type() eq 'our' ) {
                    my @variables = $parent->variables();
                    if ( scalar (@variables) == 1 and $variables[0] eq '$VERSION') {  ##no critic (RequireInterpolationOfMetachars)
                        return 1;
                    } # end if
                } # end if

                return 0;
            } # end if

            my $first_token = $parent->first_token();
            if ( $first_token->isa('PPI::Token::Word') ) {
                if ( $first_token eq 'Readonly' ) {
                    return 1;
                } # end if
            } # end if
# Uncomment once PPI bug fixed.
#        } elsif ($parent->isa('PPI::Structure::Block')) {
#            return 0;
        } # end if

        $parent = $parent->parent();
    } # end while

    return 0;
} # end _element_is_in_an_include_readonly_or_version_statement()


1;

__END__

#----------------------------------------------------------------------------

=pod

=head1 NAME

Perl::Critic::Policy::ValuesAndExpressions::ProhibitMagicNumbers

=head1 DESCRIPTION

What is a "magic number"?  A magic number is a number that appears in code
without any explanation; e.g.  C<$bank_account_balance *= 57.492;>.  You look
at that number and have to wonder where that number came from.  Since you don't
understand the significance of the number, you don't understand the code.

In general, numeric literals other than C<0> or C<1> in should not be used.
Use the L<constant> pragma or the L<Readonly> module to give a descriptive name
to the number.

There are, of course, exceptions to when this rule should be applied.  One good
example is positioning of objects in some container like shapes on a blueprint
or widgets in a UI.  In these cases, the significance of a number can readily
be determined by context.

=head2 Ways in which this module applies this rule.

By default, this rule is relaxed in that C<2> is permitted to allow for common
things like alternation, the STDERR file handle, etc..

Numeric literals are allowed in C<use> and C<require> statements to allow for
things like Perl version restrictions and L<Test::More> plans.  Uses of the
Readonly module are obviously valid.  Declarations of C<$VERSION> package
variables are permitted.

Use of binary, exponential, hexadecimal, octal, and version numbers, even for
C<0> and C<1>, outside of C<use>/C<require>/C<Readonly> statements aren't
permitted (but you can change this).



  $x = 0;                                   #ok
  $x = 0.0;                                 #ok
  $x = 1;                                   #ok
  $x = 1.0;                                 #ok
  $x = 1.5;                                 #not ok
  $x = 0b0                                  #not ok
  $x = 0b1                                  #not ok
  $x = 0x00                                 #not ok
  $x = 0x01                                 #not ok
  $x = 000                                  #not ok
  $x = 001                                  #not ok
  $x = 0e1                                  #not ok
  $x = 1e1                                  #not ok

  $frobnication_factor = 42;                #not ok
  use constant FROBNICATION_FACTOR => 42;   #ok


  use 5.6.1;                                #ok
  use Test::More plan => 57;                #ok
  our $VERSION = 0.22;                      #ok


  foreach my $solid (1..5) {                #not ok
      ...
  }


  use Readonly;

  Readonly my $REGULAR_GEOMETRIC_SOLIDS => 5;

  foreach my $solid (1..$REGULAR_GEOMETRIC_SOLIDS) {  #ok
      ...
  }





=head1 CONSTRUCTOR

This policy accepts two extra parameters: C<allowed_values> and
C<allowed_types>.

=head2 C<allowed_values>

The C<allowed_values> parameter is a whitespace delimited set of permitted
number I<values>; this does not affect the permitted formats for numbers.  The
defaults are equivalent to having the following in your F<.perlcriticrc>:

  [ValuesAndExpressions::ProhibitMagicNumbers]
  allowed_values = 0 1 2

Note that this policy forces the values C<0> and C<1> into the permitted
values.  Thus, specifying no values,

  allowed_values =

is the same as simply listing C<0> and C<1>:

  allowed_values = 0 1

The special C<all_integers> value, not surprisingly, allows all integral values
to pass, subject to the restrictions on number types.

At present, you have to specify each individual acceptable value, e.g. for -3
to 3, by .5:

  allowed_values = -3 -2.5 -2 -1.5 -1 -0.5 0 0.5 1 1.5 2 2.5 3

=head2 C<allowed_types>

The C<allowed_types> parameter is a whitespace delimited set of subclasses of
L<PPI::Token::Number>.

Decimal integers are always allowed.  By default, floating-point numbers are
also allowed.

For example, to allow hexadecimal literals, you could configure this policy
like

  [ValuesAndExpressions::ProhibitMagicNumbers]
  allowed_types = Hex

but without specifying anything for C<allowed_values>, the allowed
hexadecimal literals will be C<0x00>, C<0x01>, and C<0x02>.  Note, also, as
soon as you specify a value for this parameter, you must include C<Float> in
the list to continue to be able to use floating point literals.  This effect
can be used to restrict literals to only decimal integers:

  [ValuesAndExpressions::ProhibitMagicNumbers]
  allowed_types =

If you permit exponentials, you automatically also allow floating point values
because an exponential is a subclass of floating-point in L<PPI>.


=head1 BUGS

There is currently no way to permit version numbers in regular code, even if
you include them in the allowed_types.  Some may actually consider this a
feature.

This policy depends upon features of L<PPI> that don't exist in versions prior
to 1.119, so it disables itself if the installed version of PPI is 1.118 or
earlier.


=head1 AUTHOR

Elliot Shank C<< <perl@galumph.com> >>

=head1 COPYRIGHT

Copyright (c) 2006 Elliot Shank.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  The full text of this license
can be found in the LICENSE file included with this module.

=cut

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 expandtab :
