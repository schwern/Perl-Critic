##############################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
##############################################################################

package Perl::Critic::Policy::BuiltinFunctions::RequireBlockGrep;

# DEVELOPER NOTE: this module is used as an example in DEVELOPER.pod.
# If you make changes in here, please reflect those changes in the
# examples.

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::Critic::Utils qw{ :severities :classification :ppi };
use base 'Perl::Critic::Policy';

our $VERSION = '1.103';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{Expression form of "grep"};
Readonly::Scalar my $EXPL => [ 169 ];

#-----------------------------------------------------------------------------

sub supported_parameters { return ()                  }
sub default_severity     { return $SEVERITY_HIGH      }
sub default_themes       { return qw( core bugs pbp ) }
sub applies_to           { return 'PPI::Token::Word'  }

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, undef ) = @_;

    return if $elem->content() ne 'grep';
    return if ! is_function_call($elem);

    my $arg = first_arg($elem);
    return if !$arg;
    return if $arg->isa('PPI::Structure::Block');

    return $self->violation( $DESC, $EXPL, $elem );
}

1;

__END__

#-----------------------------------------------------------------------------

=pod

=head1 NAME

Perl::Critic::Policy::BuiltinFunctions::RequireBlockGrep - Write C<grep { $_ =~ /$pattern/ } @list> instead of C<grep /$pattern/, @list>.

=head1 AFFILIATION

This Policy is part of the core L<Perl::Critic|Perl::Critic>
distribution.


=head1 DESCRIPTION

The expression forms of C<grep> and C<map> are awkward and hard to
read.  Use the block forms instead.

    @matches = grep  /pattern/,    @list;        #not ok
    @matches = grep { /pattern/ }  @list;        #ok

    @mapped = map  transform($_),    @list;      #not ok
    @mapped = map { transform($_) }  @list;      #ok



=head1 CONFIGURATION

This Policy is not configurable except for the standard options.


=head1 SEE ALSO

L<Perl::Critic::Policy::BuiltinFunctions::ProhibitStringyEval|Perl::Critic::Policy::BuiltinFunctions::ProhibitStringyEval>

L<Perl::Critic::Policy::BuiltinFunctions::RequireBlockMap|Perl::Critic::Policy::BuiltinFunctions::RequireBlockMap>


=head1 METADATA

=head2 Explanation

=head3 First Edition of Perl Best Practices

=over

=item Pages

169


=item Chapter/Section

8/13


=back


=head2 Description

Expression form of "grep"


=head2 Default Severity

High


=head2 Default Themes

core bugs pbp


=head2 Applies To

L<PPI::Token::Word>


=head1 AUTHOR

Jeffrey Ryan Thalhammer <thaljef@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2005-2009 Jeffrey Ryan Thalhammer.  All rights reserved.

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
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
