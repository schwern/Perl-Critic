#######################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
########################################################################

package Perl::Critic::Policy::Subroutines::ProhibitBuiltinHomonyms;

use strict;
use warnings;
use Perl::Critic::Utils;
use base 'Perl::Critic::Policy';

our $VERSION = '0.18';
$VERSION = eval $VERSION;    ## no critic

#---------------------------------------------------------------------------

my %allow = ( import => 1 );
my $desc  = q{Subroutine name is a homonym for builtin function};
my $expl  = [177];

#---------------------------------------------------------------------------

sub default_severity { return $SEVERITY_HIGH }
sub applies_to { return 'PPI::Statement::Sub' }

#---------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, undef ) = @_;
    return if exists $allow{ $elem->name() };
    if ( is_perl_builtin( $elem ) ) {
        return $self->violation( $desc, $expl, $elem );
    }
    return;    #ok!
}

1;

__END__

#---------------------------------------------------------------------------

=pod

=head1 NAME

Perl::Critic::Policy::Subroutines::ProhibitBuiltinHomonyms

=head1 DESCRIPTION

Common sense dictates that you shouldn't declare subroutines with the
same name as one of Perl's built-in functions. See C<perldoc perlfunc>
for a list of built-ins.

  sub open {}  #not ok
  sub exit {}  #not ok
  sub print {} #not ok

  #You get the idea...

=head1 AUTHOR

Jeffrey Ryan Thalhammer <thaljef@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2005-2006 Jeffrey Ryan Thalhammer.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  The full text of this license
can be found in the LICENSE file included with this module.

=cut
