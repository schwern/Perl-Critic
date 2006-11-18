##################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
##################################################################

package Perl::Critic::Policy::RegularExpressions::ProhibitCaptureWithoutTest;

use strict;
use warnings;
use Perl::Critic::Utils;
use base 'Perl::Critic::Policy';

our $VERSION = 0.21;

#----------------------------------------------------------------------------

my $desc = q{Capture variable used outside conditional};
my $expl = [ 253 ];

#----------------------------------------------------------------------------

sub default_severity { return $SEVERITY_MEDIUM    }
sub default_themes   { return qw(pbp unreliable)  }
sub applies_to       { return 'PPI::Token::Magic' }

#----------------------------------------------------------------------------

sub violates {
    my ($self, $elem, $doc) = @_;
    return if $elem !~ m/\A \$\d \z/mx;
    return if $elem eq '$0';   ## no critic(RequireInterpolationOfMetachars)
    return if _is_in_conditional_expression($elem);
    return if _is_in_conditional_structure($elem);
    return $self->violation( $desc, $expl, $elem );
}

sub _is_in_conditional_expression {
    my $elem = shift;

    # simplistic check: is there one of qw(&& || ?) between a match and the capture var?
    my $psib = $elem->sprevious_sibling;
    while ($psib) {
        if ($psib->isa('PPI::Token::Operator')) {
            my $op = $psib->content;
            if ($op eq q{&&} || $op eq q{||} || $op eq q{?}) {
                $psib = $psib->sprevious_sibling;
                while ($psib) {
                    return 1 if ($psib->isa('PPI::Token::Regexp::Match'));
                    return 1 if ($psib->isa('PPI::Token::Regexp::Substitute'));
                    $psib = $psib->sprevious_sibling;
                }
                return; # false
            }
        }
        $psib = $psib->sprevious_sibling;
    }

    return; # false
}

sub _is_in_conditional_structure {
    my $elem = shift;

    my $stmt = $elem->statement();
    while ($stmt && $elem->isa('PPI::Statement::Expression')) {
       #return if _is_in_conditional_expression($stmt);
       $stmt = $stmt->statement();
    }
    return if !$stmt;

    # Check if any previous statements in the same scope have regexp matches
    my $psib = $stmt->sprevious_sibling;
    while ($psib) {
        if ($psib->isa('PPI::Node')) {  # skip tokens
            return if $psib->find_any('PPI::Token::Regexp::Match'); # fail
            return if $psib->find_any('PPI::Token::Regexp::Substitute'); # fail
        }
        $psib = $psib->sprevious_sibling;
    }

    # Check for an enclosing 'if', 'unless', 'endif', or 'else'
    my $parent = $stmt->parent;
    while ($parent) { # never false as long as we're inside a PPI::Document
        if ($parent->isa('PPI::Statement::Compound')) {
            return 1;
        }
        elsif ($parent->isa('PPI::Structure')) {
           return 1 if _is_in_conditional_expression($parent);
           return 1 if _is_in_conditional_structure($parent);
           $parent = $parent->parent;
        }
        else {
           last;
        }
    }

    return; # fail
}

1;

#----------------------------------------------------------------------------

__END__

=pod

=head1 NAME

Perl::Critic::Policy::RegularExpressions::ProhibitCaptureWithoutTest

=head1 DESCRIPTION

If a regexp match fails, then any capture variables (C<$1>, C<$2>,
...) will be undefined.  Therefore it's important to check the return
value of a match before using those variables.

This policy checks that capture variables are inside a
conditional and do not follow an regexps.

This policy does not check whether that conditional is actually
testing a regexp result, nor does it check whether a regexp actually
has a capture in it.  Those checks are too hard.

=head1 AUTHOR

Chris Dolan <cdolan@cpan.org>

=head1 COPYRIGHT

Copyright (C) 2006 Chris Dolan.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 expandtab :
