=name Basic passing

=failures 0

=cut

use 5.006_001;
require 5.006_001;

use Foo 1.0203;
require Foo 1.0203;

use Foo 1.0203 qw(foo bar);
require Foo 1.0203 qw(foo bar);

is( pcritique($policy, \$code), 0, $policy);

#----------------------------------------------------------------

=name use failure

=failures 7

=cut

use 5.6.1;
use v5.6.1;
use Foo 1.2.3;
use Foo v1.2.3;
use Foo 1.2.3 qw(foo bar);
use Foo v1.2.3 qw(foo bar);
use Foo v1.2.3 ('foo', 'bar');

#----------------------------------------------------------------

=name require failure

=failures 7

=cut

require 5.6.1;
require v5.6.1;
require Foo 1.2.3;
require Foo v1.2.3;
require Foo 1.2.3 qw(foo bar);
require Foo v1.2.3 qw(foo bar);
require Foo v1.2.3 ('foo', 'bar');

#----------------------------------------------------------------

##################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
##################################################################

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab :
