##############################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
##############################################################################

package Perl::Critic::Policy::Miscellanea::RequireVcs;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::Critic::Utils qw{
    :booleans :characters :severities :data_conversion
};

use base 'Perl::Critic::Policy';

our $VERSION = '1.117';

#-----------------------------------------------------------------------------

Readonly::Scalar my $EXPL => [ 441 ];

#-----------------------------------------------------------------------------

Readonly::Scalar my $VCS_Checks => {
    rcs         => \&_check_rcs,
    cvs         => \&_check_cvs,
    perforce    => \&_check_perforce,
    svn         => \&_check_svn,
    subversion  => \&_check_svn,
    svk         => \&_check_svk,
    git         => \&_check_git,
    hg          => \&_check_mercurial,
    mercurial   => \&_check_mercurial,
    bazaar      => \&_check_bazaar,
    darcs       => \&_check_darcs,
    unlisted    => sub { return },
};

sub supported_parameters {
    return (
        {
            name                => 'type',
            description         => 'The version control system in use.',
            default_string      => $EMPTY,
            behavior            => 'enumeration',
            enumeration_values  => [ keys %$VCS_Checks ],
            enumeration_allow_multiple_values => 0
        },
        {
            name                => 'command_path',
            description         => 'Path to the version control command.',
            default_string      => $EMPTY,
            behavior            => 'string',
        },
    );
}

# This policy doesn't need to scan the document, so violation() only needs to
# be called at most once.  Unfortunately you can't tell it to stop after
# one *check*, only after one *violation*, so we also check if we've seen a doc
# before.
sub default_maximum_violations_per_document { return 1  }

sub default_severity  { return $SEVERITY_MEDIUM         }
sub default_themes    { return qw(core pbp maintenance) }

#-----------------------------------------------------------------------------

sub initialize_if_enabled {
    return $TRUE;
}

#-----------------------------------------------------------------------------

sub _get_check {
    my $self = shift;

    my $type = $self->{_type};
    return \&_missing_type unless $type;

    my $check = $VCS_Checks->{$type};
    return \&_invalid_type unless $check;

    return $check;
}

sub _missing_type {
    my $self = shift;
    my $elem = shift;

    my $desc = "Version control type not specified, please set 'type' in your .perlcriticrc";
    return $self->violation( $desc, $EXPL, $elem );
}

sub _invalid_type {
    my $self = shift;
    my $elem = shift;

    my $type = $self->{_type};
    my $desc = "'$type' is not a recognized version control system.  Consider using the 'unlisted' type";
    return $self->violation( $desc, $EXPL, $elem );
}


sub _seen_doc {
    my( $self, $doc ) = @_;

    my $seen_doc = $self->{_docs_seen}{$doc};
    $self->{_docs_seen}{$doc}++;

    return $seen_doc;
}


sub violates {
    my( $self, $elem, $doc ) = @_;

    # We've already checked this document, no need to do it again.
    return if $self->_seen_doc($doc);

    my $check = $self->_get_check;

    my $violation = $self->$check($doc);

    return unless $violation;
    return $violation;
}

__END__

#-----------------------------------------------------------------------------

=pod

=head1 NAME

Perl::Critic::Policy::Miscellanea::RequireVcs - Use a version control system


=head1 AFFILIATION

This Policy is part of the core L<Perl::Critic|Perl::Critic>
distribution.


=head1 DESCRIPTION

Every code file, no matter how small, should be using a version
control system (VCS).  This policy checks that your project is using
one.

=head1 CONFIGURATION

This policy B<requires> that you specify the type of version control
in use, else the policy will be considered in violation.

    [Miscellanea::RequireVcs]
    type = git

Recognized version control systems are rcs, cvs, perforce, subversion
(aka svn), svk git, mercurial (aka hg), bazaar and darcs.

A special value of C<unlisted> is available if your version control is
not known by this policy.  Using unlisted will satisfy the policy.  We
ask that you please report unlisted version control systems and we'll
try to support them.

The policy will usually try to verify the file is under version
control by issuing a version control command.  If the command is not
in your C<PATH>, or uses an unusual name, you can specify a relative
or full path to the command with C<command_path>.

    [Miscellanea::RequireVcs]
    command_path = /opt/local/git/bin/git


=head1 AUTHOR

Michael G Schwern <schwern@pobox.com>


=head1 COPYRIGHT

Copyright (c) 2012 Michael G Schwern <schwern@pobox.com>

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
