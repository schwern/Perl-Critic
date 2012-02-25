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
use List::MoreUtils qw(uniq);
use File::Spec;
use File::Basename qw(dirname basename);

use Perl::Critic::Utils qw{
    :booleans :characters :severities :data_conversion
};

use base 'Perl::Critic::Policy';

our $VERSION = '1.117';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{The file does not appear to be under version control};
Readonly::Scalar my $EXPL => [ 441 ];

#-----------------------------------------------------------------------------

# Identifying directories for various version control systems.
# The policy will look up directories for them.
my $VCS_Dirs = {
    cvs                 => "CVS",
    subversion          => ".svn",
    git                 => ".git",
    mercurial           => ".hg",
    bazaar              => ".bzr",
    darcs               => "_darcs",
};
$VCS_Dirs->{perforce} = $ENV{P4CONFIG} if $ENV{P4CONFIG};

# Common aliases and abbreviations.
Readonly::Scalar my $VCS_Aliases => {
    svn         => "subversion",
    SVN         => "subversion",

    CVS         => "cvs",

    RCS         => "rcs",

    hg          => "mercurial",

    bzr         => "bazaar",

    p4          => "perforce",
    P4          => "perforce",

    SVK         => "svk",
};

# Version control systems which may require special logic to identify.
Readonly::Scalar my $VCS_Special_Checks => {
    # Check for the RCS ,v file.
    rcs         => sub {
        my $self = shift;

        my $dir  = dirname( $self->{_filename} );
        my $file = basename( $self->{_filename} );
        my $vcs_file = $file.",v";

        return -e File::Spec->catfile($dir, $vcs_file)          ||
               -e File::Spec->catfile($dir, "RCS", $vcs_file);
    },
};

# A hash of VCS's we cannot check for.
Readonly::Scalar my $Uncheckable_VCS => {
    map { $_ => 1 } qw(
        svk
        unlisted
    )
};

# A list of all the VCS names we recognize.
Readonly::Scalar my $All_VCS_Names => [uniq(
    keys   %$Uncheckable_VCS,
    keys   %$VCS_Dirs,
    keys   %$VCS_Special_Checks,
    keys   %$VCS_Aliases
)];

sub supported_parameters {
    return (
        {
            name                => 'type',
            description         => 'The version control system in use.',
            default_string      => $EMPTY,
            behavior            => 'enumeration',
            enumeration_values  => [ @$All_VCS_Names ],
            enumeration_allow_multiple_values => 0
        }
    );
}

# This makes the policy only apply once per file.
sub applies_to        { return 'PPI::Document' }

sub default_severity  { return $SEVERITY_MEDIUM         }
sub default_themes    { return qw(core pbp maintenance) }

#-----------------------------------------------------------------------------

sub _resolve_type_alias {
    my( $self, $type ) = @_;

    my $new_type = $VCS_Aliases->{$type};
    return defined $new_type ? $new_type : $type;
}

sub _check_one_type {
    my($self, $type) = @_;

    $type = $self->_resolve_type_alias($type);
    return $self->_is_uncheckable($type)   ||
           $self->_do_special_check($type) ||
           $self->_look_up_dirs($type)     ||
           $FALSE;
}

sub _check_all_types {
    my($self) = @_;

    return $self->_do_special_checks || $self->_look_up_dirs || $FALSE;
}

sub _is_uncheckable {
    my($self, $type) = @_;

    return $type if $Uncheckable_VCS->{$type};
    return $FALSE;
}

sub _do_special_check {
    my($self, $type) = @_;

    my $check = $VCS_Special_Checks->{$type};
    return $FALSE unless $check;

    return $type if $self->$check();
}

sub _do_special_checks {
    my($self) = @_;

    for my $type (keys %$VCS_Special_Checks) {
        return $type if $self->_do_special_check($type);
    }

    return $FALSE;
}

# Starting at the current directory, look up the directory tree for
# VCS directories.
sub _look_up_dirs {
    my $self = shift;

    my @types = @_ ? shift : keys %$VCS_Dirs;

    my $updir = File::Spec->updir;
    my $dir   = $self->{_dir};
    my $max_up = 1024;
    my $ups    = 0;
    while( -d $dir ) {
        for my $type (@types) {
            my $type = $self->_look_in_dir($type, $dir);
            return $type if $type;
        }

        $dir = File::Spec->catdir( $dir, $updir );

        $ups++;
        die "Probably in an infinite loop" if $ups > $max_up;
    }

    return $FALSE;
}

sub _look_in_dir {
    my( $self, $type, $dir ) = @_;

    my $vcs_dir = $VCS_Dirs->{$type};
    return $FALSE unless $vcs_dir;

    return $type if -d File::Spec->catdir($dir, $vcs_dir);

    return $FALSE;
}

sub violates {
    my( $self, $elem, $doc ) = @_;

    # Get the filename we're examining.
    $self->{_filename} = $doc->filename;

    # Derive the directory the file lives in.
    my @path = File::Spec->splitpath( $self->{_filename } );
    pop @path;
    $self->{_dir} = File::Spec->catpath(@path, "");

    if( my $type = $self->{_type} ) {
        return if $self->_check_one_type($type);
    }
    else {
        return if $self->_check_all_types;
    }

    return $self->violation( $DESC, $EXPL, $doc );
}

1;

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

The policy will guess what version control system you're using, but you can
also just tell it by setting the C<type>.

    [Miscellanea::RequireVcs]
    type = git

Recognized version control systems are rcs, cvs, perforce (aka p4), subversion
(aka svn), svk, git, mercurial (aka hg), bazaar and darcs.

SVK cannot currently be detected.  If you're using it, simply set the
C<type> to C<svk> and the policy will give you a free pass.

A special value of C<unlisted> is available if your version control is
not known by this policy.  Using unlisted will satisfy the policy.  We
ask that you please report unlisted version control systems and we'll
try to support them.


=head1 NOTES

Unlike other policies, this policy does not look at your code but
rather your environment.  It should B<only> be run as part of the
development process and B<should not> be run as part of normal
installation.


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
