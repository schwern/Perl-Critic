#######################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
########################################################################

package Perl::Critic::Policy::ValuesAndExpressions::RequireInterpolationOfMetachars;

use strict;
use warnings;
use Perl::Critic::Utils;
use Perl::Critic::Violation;
use base 'Perl::Critic::Policy';

our $VERSION = '0.13_02';
$VERSION = eval $VERSION;    ## no critic

#---------------------------------------------------------------------------

my $desc = q{String *may* require interpolation};
my $expl = [ 51 ];

#---------------------------------------------------------------------------

sub default_severity   { return $SEVERITY_LOWEST }
sub applies_to {
    return 'PPI::Token::Quote::Single', 'PPI::Token::Quote::Literal';
}

#---------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, $doc ) = @_;
    if ( _has_interpolation($elem) ) {
        my $sev = $self->get_severity();
        return Perl::Critic::Violation->new( $desc, $expl, $elem, $sev );
    }
    return;    #ok;
}

sub _has_interpolation {
    my $elem = shift || return;
    return $elem =~ m{ (?<!\\) [\$\@] \S+ }mx      #Contains unescaped $. or @.
      || $elem   =~ m{ \\[tnrfae0xcNLuLUEQ] }mx;   #Containts escaped metachars
}

1;

__END__

#---------------------------------------------------------------------------

=pod

=head1 NAME

Perl::Critic::Policy::ValuesAndExpressions::RequireInterpolationOfMetachars

=head1 DESCRIPTION

This policy warns you if you use single-quotes or C<q//> with a string
that has unescaped metacharacters that may need interpoation. Its hard
to know for sure if a string really should be interpolated without
looking into the symbol table.  This policy just makes an educated
guess by looking for metachars and sigils which usually indicate that
the string should be interpolated.

=head1 NOTES

Perl's own C<warnings> pragma also warns you about this.

=head1 SEE ALSO

L<Perl::Critic::Policy::ValuesAndExpressions::ProhibitInterpolationOfLiterals>

=head1 AUTHOR

Jeffrey Ryan Thalhammer <thaljef@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2005 Jeffrey Ryan Thalhammer.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  The full text of this license
can be found in the LICENSE file included with this module.

=cut
