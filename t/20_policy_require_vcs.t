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

use Test::More tests => 4;

use File::Path;
use File::Basename qw(dirname);
use File::Spec;
use File::Temp;
use Cwd qw(abs_path);
use Readonly;

Readonly::Scalar my $ORIG_CWD => abs_path();
Readonly::Scalar my $POLICY   => "Miscellanea::RequireVcs";

sub write_file {
    my( $file, $text ) = @_;

    my $dir = dirname($file);
    mkpath $dir unless -d $dir;

    open my $fh, '>', $file or die "Unable to open $file: $!";
    print $fh $text;
    close $fh or die "Can't close $file: $!";
}


{
    my $tmp = File::Temp->newdir;
    ok chdir $tmp;

    my $pm_file = File::Spec->catdir("lib", "Some.pm");
    write_file $pm_file, <<'END';
$foo = 42;
END

    my $c = Perl::Critic->new( -profile => 'NONE' );
    $c->add_policy(-policy => $POLICY);

    my @violations = $c->critique($pm_file);
    is @violations, 1;

    ok mkdir '.git';
    @violations = $c->critique($pm_file);
    is @violations, 0;
}

chdir $ORIG_CWD;
