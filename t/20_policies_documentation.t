##################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
##################################################################

use strict;
use warnings;
use Test::More tests => 8;
use Perl::Critic::Config;
use Perl::Critic;

# common P::C testing tools
use lib qw(t/tlib);
use PerlCriticTestUtils qw(pcritique);
PerlCriticTestUtils::block_perlcriticrc();

my $code;
my $policy;

#----------------------------------------------------------------

$code = <<'END_PERL';
#Nothing!
END_PERL

$policy = 'Documentation::RequirePodAtEnd';
is( pcritique($policy, \$code), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
__END__
#Nothing!
END_PERL

$policy = 'Documentation::RequirePodAtEnd';
is( pcritique($policy, \$code), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
=head1 Foo

=cut
END_PERL

$policy = 'Documentation::RequirePodAtEnd';
is( pcritique($policy, \$code), 1, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
__END__

=head1 Foo

=cut
END_PERL

$policy = 'Documentation::RequirePodAtEnd';
is( pcritique($policy, \$code), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';

=for comment
This POD is ok
=cut

__END__

=head1 Foo

=cut
END_PERL

$policy = 'Documentation::RequirePodAtEnd';
is( pcritique($policy, \$code), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';

=for comment
This POD is ok
=cut

=head1 Foo

This POD is illegal

=cut

=begin comment

This POD is ok

This POD is also ok

=end comment

=cut

__END__

=head1 Bar

=cut
END_PERL

$policy = 'Documentation::RequirePodAtEnd';
is( pcritique($policy, \$code), 1, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';

=for comment
This is a one-line comment

=cut

my $baz = 'nuts';

__END__

END_PERL

$policy = 'Documentation::RequirePodAtEnd';
is( pcritique($policy, \$code), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';

=begin comment

Multi-paragraph comment

Mutli-paragrapm comment

=end comment

=cut

__END__

END_PERL

$policy = 'Documentation::RequirePodAtEnd';
is( pcritique($policy, \$code), 0, $policy);




