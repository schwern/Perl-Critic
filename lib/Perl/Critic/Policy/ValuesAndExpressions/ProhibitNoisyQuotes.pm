##############################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
##############################################################################

package Perl::Critic::Policy::ValuesAndExpressions::ProhibitNoisyQuotes;

use strict;
use warnings;
use Readonly;

use Perl::Critic::Utils qw{ :severities };
use base 'Perl::Critic::Policy';

our $VERSION = 1.073;

#-----------------------------------------------------------------------------

Readonly::Scalar my $NOISE_RX => qr{\A ["|']  [^ \w () {} [\] <> ]{1,2}  ['|"] \z}mx;
Readonly::Scalar my $DESC     => q{Quotes used with a noisy string};
Readonly::Scalar my $EXPL     => [ 53 ];

#-----------------------------------------------------------------------------

sub supported_parameters { return ()                    }
sub default_severity     { return $SEVERITY_LOW         }
sub default_themes       { return qw(core pbp cosmetic) }
sub applies_to           { return qw(PPI::Token::Quote::Double
                                     PPI::Token::Quote::Single) }

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, undef ) = @_;
    return if $elem !~ $NOISE_RX;
    my $statement = $elem->statement;
    return if $statement
        && $statement->isa('PPI::Statement::Include')
        && $statement->type eq 'use'
        && $statement->module eq 'overload';
    return $self->violation( $DESC, $EXPL, $elem );
}

1;

__END__

#-----------------------------------------------------------------------------

=pod

=head1 NAME

Perl::Critic::Policy::ValuesAndExpressions::ProhibitNoisyQuotes

=head1 DESCRIPTION

Don't use quotes for one or two-character strings of non-alphanumeric
characters (i.e. noise).  These tend to be hard to read.  For
legibility, use C<q{}> or a named value.  However, braces, parens, and
brackets tend do to look better in quotes, so those are allowed.

  $str = join ',', @list;     #not ok
  $str = join ",", @list;     #not ok
  $str = join q{,}, @list;    #better

  $COMMA = q{,};
  $str = join $COMMA, @list;  #best

  $lbrace = '(';          #ok
  $rbrace = ')';          #ok
  print '(', @list, ')';  #ok

=head1 SEE ALSO

L<Perl::Critic::Policy::ValuesAndExpressions::ProhibitEmptyQuotes>

=head1 AUTHOR

Jeffrey Ryan Thalhammer <thaljef@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2005-2007 Jeffrey Ryan Thalhammer.  All rights reserved.

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
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab :
