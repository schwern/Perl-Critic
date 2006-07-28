##################################################################
#      $URL: http://perlcritic.tigris.org/svn/perlcritic/trunk/Perl-Critic/lib/Perl/Critic/Policy/BuiltinFunctions/RequireBlockGrep.pm $
#     $Date: 2006-07-24 00:53:20 -0700 (Mon, 24 Jul 2006) $
#   $Author: thaljef $
# $Revision: 537 $
# ex: set ts=8 sts=4 sw=4 expandtab
##################################################################

package Perl::Critic::Policy::ErrorHandling::RequireCarping;

use strict;
use warnings;
use Perl::Critic::Utils;
use base 'Perl::Critic::Policy';

our $VERSION = '0.18_01';
$VERSION = eval $VERSION;    ## no critic

#----------------------------------------------------------------------------

my $expl = [ 169 ];

#----------------------------------------------------------------------------

sub default_severity { return $SEVERITY_MEDIUM }
sub applies_to { return 'PPI::Token::Word' }

#----------------------------------------------------------------------------

sub violates {

    my ( $self, $elem, undef ) = @_;

    return if ($elem ne 'warn' && $elem ne 'die');
    return if is_method_call($elem);
    return if is_hash_key($elem);
    return if is_subroutine_name($elem);

    # Must be a call to 'die' or 'warn'
    my $alternative = $elem eq 'warn' ? 'carp' : 'croak';
    my $expl qq{'$elem' used instead of '$alternative'};
    return $self->violation( $desc, $expl, $elem );
}


1;

__END__

#----------------------------------------------------------------------------

=pod

=head1 NAME

Perl::Critic::Policy::ErrorHandling::RequireCarping

=head1 DESCRIPTION

The C<die> and C<warn> functions both report the file and line number
where the exception ocurred.  But if someone else is using your
subroutine, they usually don't care where B<your> code blew up.
Instead, they want to know where B<their> code invoked the subroutine.
The L<Carp> module provides alternative methods that report the
exception from the caller's file and line number.


=head1 AUTHOR

Jeffrey Ryan Thalhammer <thaljef@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2005-2006 Jeffrey Ryan Thalhammer.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  The full text of this license
can be found in the LICENSE file included with this module.

=cut
