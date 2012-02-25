#!perl

##############################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
##############################################################################

use 5.006001;
use strict;
use warnings;

use Perl::Critic::TestUtils qw< fcritique >;
use Perl::Critic::Utils     qw< $EMPTY >;

use Test::More;

use File::Path;
use File::Basename qw(dirname);
use File::Spec;
use File::Temp;
use Cwd qw(abs_path);
use Readonly;

Readonly::Scalar my $ORIG_CWD => abs_path();
Readonly::Scalar my $POLICY   => "Miscellanea::RequireVcs";
Readonly::Hash   my %VCS_DIRS => (
    cvs         => 'CVS',
    svn         => '.svn',
    git         => '.git',
    mercurial   => '.hg',
    bazaar      => '.bzr',
    darcs       => '_darcs',
);

sub write_file {
    my( $file, $text ) = @_;

    my $dir = dirname($file);
    mkpath $dir unless -d $dir;

    open my $fh, '>', $file or die "Unable to open $file: $!";
    print $fh $text;
    close $fh or die "Can't close $file: $!";

    return;
}


note "Testing simple VCS directory checks";
for my $vcs_type (keys %VCS_DIRS) {
    my $vcs_dir = $VCS_DIRS{$vcs_type};

    note "Testing $vcs_type with $vcs_dir";

    my $tmp = File::Temp->newdir;
    ok chdir $tmp;

    my $pm_file = File::Spec->catdir("lib", "Some.pm");
    write_file $pm_file, <<'END';
$foo = 42;
END

    my $critic_no_type = Perl::Critic->new( -profile => 'NONE' );
    $critic_no_type->add_policy(-policy => $POLICY);

    my $critic_right_type = Perl::Critic->new( -profile => 'NONE' );
    $critic_right_type->add_policy(-policy => $POLICY, -config => { type => $vcs_type });

    my $critic_wrong_type = Perl::Critic->new( -profile => 'NONE' );
    $critic_wrong_type->add_policy(-policy => $POLICY, -config => { type => 'rcs' });

    my @violations;

    # Try various configs with no VCS dir.  All should fail.
    @violations = $critic_no_type->critique($pm_file);
    is @violations, 1, "no VCS dir, no type";

    @violations = $critic_right_type->critique($pm_file);
    is @violations, 1, "no VCS dir, right type";

    @violations = $critic_wrong_type->critique($pm_file);
    is @violations, 1, "no VCS dir, wrong type";

    # Create the VCS dir
    ok mkdir $vcs_dir;

    @violations = $critic_no_type->critique($pm_file);
    is @violations, 0, "VCS dir, no type";

    @violations = $critic_right_type->critique($pm_file);
    is @violations, 0, "VCS dir, right type";

    @violations = $critic_wrong_type->critique($pm_file);
    is @violations, 1, "VCS dir, wrong type";
}

# File::Temp tends to complain if the temp directory you're currently in
# goes away before END time.
chdir $ORIG_CWD;


done_testing;
