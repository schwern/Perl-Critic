=name Basic passing

=failures 0

=cut

$var = q{'};
$var = q{"};
$var = q{!!};
$var = q{||};
$var = "!!!";
$var = '!!!';
$var = 'a';
$var = "a";
$var = '1';
$var = "1";

#----------------------------------------------------------------

=name Basic failure

=failures 4

=cut

$var = "!";
$var = '!';
$var = '!!';
$var = "||";

#----------------------------------------------------------------

=name overload pragma

=failures 0

=cut

use overload '""';

#----------------------------------------------------------------

=name Parentheses, braces, brackets

=failures 0

=cut

$var = '(';
$var = ')';
$var = '{';
$var = '}';
$var = '[';
$var = ']';

$var = '{(';
$var = ')}';
$var = '[{';
$var = '[}';
$var = '[(';
$var = '])';

$var = "(";
$var = ")";
$var = "{";
$var = "}";
$var = "[";
$var = "]";

$var = "{(";
$var = ")]";
$var = "({";
$var = "}]";
$var = "{[";
$var = "]}";

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
