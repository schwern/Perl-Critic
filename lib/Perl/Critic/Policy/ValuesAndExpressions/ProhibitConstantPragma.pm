#######################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
########################################################################

package Perl::Critic::Policy::ValuesAndExpressions::ProhibitConstantPragma;

use strict;
use warnings;
use Perl::Critic::Utils;
use Perl::Critic::Violation;
use base 'Perl::Critic::Policy';

our $VERSION = '0.15_03';
$VERSION = eval $VERSION;    ## no critic

#---------------------------------------------------------------------------

my $desc = q{Pragma 'constant' used};
my $expl = [ 55 ];

#---------------------------------------------------------------------------

sub default_severity { return $SEVERITY_HIGH }
sub applies_to { return 'PPI::Statement::Include' }

#---------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, $doc ) = @_;
    if ( $elem->type() eq 'use' && $elem->pragma() eq 'constant' ) {
        my $sev = $self->get_severity();
        return Perl::Critic::Violation->new( $desc, $expl, $elem, $sev );
    }
    return;    #ok!
}

1;

__END__

#---------------------------------------------------------------------------

=pod

=head1 NAME

Perl::Critic::Policy::ValuesAndExpressions::ProhibitConstantPragma

=head1 DESCRIPTION

Named constants are a good thing.  But don't use the C<constant>
pragma because barewords don't interpolate.  Instead use the
L<Readonly> module.

  use constant FOOBAR => 42;  #not ok

  use Readonly;
  Readonly  my $FOOBAR => 42;  #ok

=head1 AUTHOR

Jeffrey Ryan Thalhammer <thaljef@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2005-2006 Jeffrey Ryan Thalhammer.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  The full text of this license
can be found in the LICENSE file included with this module.

=cut
