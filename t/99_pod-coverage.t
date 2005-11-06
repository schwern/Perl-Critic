##################################################################
#     $URL$
#    $Date$
#   $Author$
# $Revision$
##################################################################

use strict;
use warnings;
use Test::More;

eval 'use Test::Pod::Coverage 1.00';
plan skip_all => 'Test::Pod::Coverage 1.00 requried to test POD' if $@;
my $trustme = { trustme => [ qr{ \A (?: new | violates | applies_to ) \z }x ] };
all_pod_coverage_ok($trustme);