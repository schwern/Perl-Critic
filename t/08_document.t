#!perl

##############################################################################
#     $URL$
#    $Date$
#   $Author$
# $Revision$
##############################################################################

use 5.006001;
use strict;
use warnings;

use Carp qw< carp >;

use version;

use Perl::Critic::Utils::DataConversion qw< dor >;

use Test::More tests => 36;

#-----------------------------------------------------------------------------

our $VERSION = '1.103';

#-----------------------------------------------------------------------------

use_ok('Perl::Critic::Document');
can_ok('Perl::Critic::Document', 'new');
can_ok('Perl::Critic::Document', 'filename');
can_ok('Perl::Critic::Document', 'highest_explicit_perl_version');
can_ok('Perl::Critic::Document', 'ppi_document');
can_ok('Perl::Critic::Document', 'document_type');
can_ok('Perl::Critic::Document', 'is_script');
can_ok('Perl::Critic::Document', 'is_module');

{
    my $code = q{'print 'Hello World';};  #Has 6 PPI::Element
    my $ppi_doc = PPI::Document->new( \$code );
    my $pc_doc  = Perl::Critic::Document->new( '-source' => $ppi_doc );
    isa_ok($pc_doc, 'Perl::Critic::Document');
    isa_ok($pc_doc, 'PPI::Document');
    isa_ok($pc_doc, 'PPI::Node');
    isa_ok($pc_doc, 'PPI::Element');


    my $nodes_ref = $pc_doc->find('PPI::Element');
    is( scalar @{ $nodes_ref }, 6, 'find by class name');

    $nodes_ref = $pc_doc->find( sub{ return 1 } );
    is( scalar @{ $nodes_ref }, 6, 'find by wanted() handler');

    $nodes_ref = $pc_doc->find( q{Element} );
    is( scalar @{ $nodes_ref }, 6, 'find by shortened class name');

    #---------------------------

    my $node = $pc_doc->find_first('PPI::Element');
    is( ref $node, 'PPI::Statement', 'find_first by class name');

    $node = $pc_doc->find_first( sub{ return 1 } );
    is( ref $node, 'PPI::Statement', 'find_first by wanted() handler');

    $node = $pc_doc->find_first( q{Element} );
    is( ref $node, 'PPI::Statement', 'find_first by shortened class name');

    #---------------------------

    my $found = $pc_doc->find_any('PPI::Element');
    is( $found, 1, 'find_any by class name');

    $found = $pc_doc->find_any( sub{ return 1 } );
    is( $found, 1, 'find_any by wanted() handler');

    $found = $pc_doc->find_any( q{Element} );
    is( $found, 1, 'find_any by shortened class name');

    #-------------------------------------------------------------------------

    {
        # Ignore "Cannot create search condition for 'PPI::': Not a PPI::Element"
        local $SIG{__WARN__} = sub {
            $_[0] =~ m/\QCannot create search condition for\E/xms || carp @_
        };
        $nodes_ref = $pc_doc->find( q{} );
        is( $nodes_ref, undef, 'find by empty class name');

        $node = $pc_doc->find_first( q{} );
        is( $node, undef, 'find_first by empty class name');

        $found = $pc_doc->find_any( q{} );
        is( $found, undef, 'find_any by empty class name');

    }

    #-------------------------------------------------------------------------

    is( $pc_doc->document_type(), 'module', q{default document_type is 'module'});
    ok( $pc_doc->is_module(), q{document type 'module' is a module});
    ok( ! $pc_doc->is_script(), q{document type 'module' is not a script});

    #-------------------------------------------------------------------------

    is($pc_doc->filename(), undef, q{default filename is undefined});

    my $named_pc_doc = Perl::Critic::Document->new(
        '-source' => $ppi_doc,
        '-as-filename' => 'foo.pl',
        '-script-extensions' => ['.pl']
    );

    is($named_pc_doc->filename(), 'foo.pl', q{using user-specified filename});
    ok($named_pc_doc->is_script(), q{user-specified filename is a script});
}

#-----------------------------------------------------------------------------

{
    test_version( 'sub { 1 }', undef );
    test_version( 'use 5.006', version->new('5.006') );
    test_version( 'use 5.8.3', version->new('5.8.3') );
    test_version(
        'use 5.006; use 5.8.3; use 5.005005',
        version->new('5.8.3'),
    );
    test_version( 'use 5.005_05; use 5.005_03', version->new('5.005_05') );
    test_version( 'use 5.005_03; use 5.005_05', version->new('5.005_05') );
}

sub test_version {
    my ($code, $expected_version) = @_;

    my $description_version = dor( $expected_version, '<undef>' );

    my $document =
        Perl::Critic::Document->new(
            '-source' => PPI::Document->new( \$code )
        );

    is(
        $document->highest_explicit_perl_version(),
        $expected_version,
        qq<Get "$description_version" for "$code".>,
    );

    return;
}

#-----------------------------------------------------------------------------

# ensure we run true if this test is loaded by
# t/08_document.t_without_optional_dependencies.t
1;

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
