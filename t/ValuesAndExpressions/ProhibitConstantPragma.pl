=name Basic passing

=failures 0

=cut

my $FOO = 42;
local BAR = 24;
our $NUTS = 16;

#----------------------------------------------------------------

=name Basic failure

=failures 2

=cut

use constant FOO => 42;
use constant BAR => 24;

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
