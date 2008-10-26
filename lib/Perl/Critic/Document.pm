##############################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
##############################################################################

package Perl::Critic::Document;

use 5.006001;
use strict;
use warnings;

use List::Util qw< max >;
use PPI::Document;
use Scalar::Util qw< weaken >;
use version;

#-----------------------------------------------------------------------------

our $VERSION = '1.093_01';

#-----------------------------------------------------------------------------

our $AUTOLOAD;
sub AUTOLOAD {  ## no critic (ProhibitAutoloading,ArgUnpacking)
    my ( $function_name ) = $AUTOLOAD =~ m/ ([^:\']+) \z /xms;
    return if $function_name eq 'DESTROY';
    my $self = shift;
    return $self->{_doc}->$function_name(@_);
}

#-----------------------------------------------------------------------------

sub new {
    my ($class, $doc) = @_;
    my $self = bless {}, $class;
    $self->{_disabled_lines} = _unfix_shebang($doc);
    $self->{_doc} = $doc;
    return $self;
}

#-----------------------------------------------------------------------------

sub ppi_document {
    my ($self) = @_;
    return $self->{_doc};
}

#-----------------------------------------------------------------------------

sub isa {
    my ($self, @args) = @_;
    return $self->SUPER::isa(@args)
        || ( (ref $self) && $self->{_doc} && $self->{_doc}->isa(@args) );
}

#-----------------------------------------------------------------------------

sub find {
    my ($self, $wanted, @more_args) = @_;

    # This method can only find elements by their class names.  For
    # other types of searches, delegate to the PPI::Document
    if ( ( ref $wanted ) || !$wanted || $wanted !~ m/ \A PPI:: /xms ) {
        return $self->{_doc}->find($wanted, @more_args);
    }

    # Build the class cache if it doesn't exist.  This happens at most
    # once per Perl::Critic::Document instance.  %elements of will be
    # populated as a side-effect of calling the $finder_sub coderef
    # that is produced by the caching_finder() closure.
    if ( !$self->{_elements_of} ) {

        my %cache = ( 'PPI::Document' => [ $self ] );

        # The cache refers to $self, and $self refers to the cache.  This
        # creates a circular reference that leaks memory (i.e.  $self is not
        # destroyed until execution is complete).  By weakening the reference,
        # we allow perl to collect the garbage properly.
        weaken( $cache{'PPI::Document'}->[0] );

        my $finder_coderef = _caching_finder( \%cache );
        $self->{_doc}->find( $finder_coderef );
        $self->{_elements_of} = \%cache;
    }

    # find() must return false-but-defined on fail
    return $self->{_elements_of}->{$wanted} || q{};
}

#-----------------------------------------------------------------------------

sub find_first {
    my ($self, $wanted, @more_args) = @_;

    # This method can only find elements by their class names.  For
    # other types of searches, delegate to the PPI::Document
    if ( ( ref $wanted ) || !$wanted || $wanted !~ m/ \A PPI:: /xms ) {
        return $self->{_doc}->find_first($wanted, @more_args);
    }

    my $result = $self->find($wanted);
    return $result ? $result->[0] : $result;
}

#-----------------------------------------------------------------------------

sub find_any {
    my ($self, $wanted, @more_args) = @_;

    # This method can only find elements by their class names.  For
    # other types of searches, delegate to the PPI::Document
    if ( ( ref $wanted ) || !$wanted || $wanted !~ m/ \A PPI:: /xms ) {
        return $self->{_doc}->find_any($wanted, @more_args);
    }

    my $result = $self->find($wanted);
    return $result ? 1 : $result;
}

#-----------------------------------------------------------------------------

sub filename {
    my ($self) = @_;
    return $self->{_doc}->can('filename') ? $self->{_doc}->filename : undef;
}

#-----------------------------------------------------------------------------

sub highest_explicit_perl_version {
    my ($self) = @_;

    my $highest_explicit_perl_version =
        $self->{_highest_explicit_perl_version};

    if ( not exists $self->{_highest_explicit_perl_version} ) {
        my $includes = $self->find( \&_is_a_version_statement );

        if ($includes) {
            # Note: this will complain about underscores, e.g. "use
            # 5.008_000".  However, nothing important should be depending upon
            # alpha perl versions and marking non-alpha versions as alpha is
            # bad in and of itself.  Note that this contradicts an example in
            # perlfunc about "use".
            $highest_explicit_perl_version =
                max map { version->new( $_->version() ) } @{$includes};
        }
        else {
            $highest_explicit_perl_version = undef;
        }

        $self->{_highest_explicit_perl_version} =
            $highest_explicit_perl_version;
    }

    return $highest_explicit_perl_version if $highest_explicit_perl_version;
    return;
}

#-----------------------------------------------------------------------------

sub mark_disabled_lines {
    my ($self, @site_policies) = @_;
    my %disabled_lines = _find_disabled_lines($self->{_doc}, @site_policies);

    # Ick.  Need to merge the disabled lines hash with the shebang lines
    # that we alread disabled during the _unfix_shebang() process.  Need
    # to find a better way to express this.

    $self->{_disabled_lines} = { %{$self->{_disabled_lines}}, %disabled_lines };
    return $self;
}

#-----------------------------------------------------------------------------

sub is_line_disabled {
    my ($self, $line, $policy_name) = @_;
    return 0 if not exists $self->{_disabled_lines}->{$line};
    return 1 if $self->{_disabled_lines}->{$line}->{$policy_name};
    return 1 if $self->{_disabled_lines}->{$line}->{ALL};
    return 0;
}

#-----------------------------------------------------------------------------

sub _is_a_version_statement {
    my (undef, $element) = @_;

    return 0 if not $element->isa('PPI::Statement::Include');
    return 1 if $element->version();
    return 0;
}

#-----------------------------------------------------------------------------

sub _caching_finder {

    my $cache_ref = shift;  # These vars will persist for the life
    my %isa_cache = ();     # of the code ref that this sub returns


    # Gather up all the PPI elements and sort by @ISA.  Note: if any
    # instances used multiple inheritance, this implementation would
    # lead to multiple copies of $element in the $elements_of lists.
    # However, PPI::* doesn't do multiple inheritance, so we are safe

    return sub {
        my (undef, $element) = @_;
        my $classes = $isa_cache{ref $element};
        if ( !$classes ) {
            $classes = [ ref $element ];
            # Use a C-style loop because we append to the classes array inside
            for ( my $i = 0; $i < @{$classes}; $i++ ) { ## no critic(ProhibitCStyleForLoops)
                no strict 'refs';                       ## no critic(ProhibitNoStrict)
                push @{$classes}, @{"$classes->[$i]::ISA"};
                $cache_ref->{$classes->[$i]} ||= [];
            }
            $isa_cache{$classes->[0]} = $classes;
        }

        for my $class ( @{$classes} ) {
            push @{$cache_ref->{$class}}, $element;
        }

        return 0; # 0 tells find() to keep traversing, but not to store this $element
    };
}

#-----------------------------------------------------------------------------

sub _find_disabled_lines {

    my ($doc, @site_policies)= @_;

    my $nodes_ref  = $doc->find('PPI::Token::Comment') || return;
    my %disabled_lines;

    _disable_shebang_line($nodes_ref, \%disabled_lines, \@site_policies);
    _disable_other_lines($nodes_ref, \%disabled_lines, \@site_policies);
    return %disabled_lines;
}

#-----------------------------------------------------------------------------

sub _disable_shebang_line {
    my ($nodes_ref, $disabled_lines, $site_policies) = @_;

    my $shebang_no_critic  = qr{\A [#]! .*? [#][#] \s* no  \s+ critic}xms;

    # Special case for the very beginning of the file: allow "##no critic" after the shebang
    if (0 < @{$nodes_ref}) {
        my $loc = $nodes_ref->[0]->location;
        if (1 == $loc->[0] && 1 == $loc->[1] && $nodes_ref->[0] =~ $shebang_no_critic) {
            my $pragma = shift @{$nodes_ref};
            for my $policy (_parse_nocritic_import($pragma, $site_policies)) {
                $disabled_lines->{ 1 }->{$policy} = 1;
            }
        }
    }
    return;
}

#-----------------------------------------------------------------------------

sub _disable_other_lines {
    my ($nodes_ref, $disabled_lines, $site_policies) = @_;

    my $no_critic  = qr{\A \s* [#][#] \s* no  \s+ critic}xms;
    my $use_critic = qr{\A \s* [#][#] \s* use \s+ critic}xms;

  PRAGMA:
    for my $pragma ( grep { $_ =~ $no_critic } @{$nodes_ref} ) {

        # Parse out the list of Policy names after the
        # 'no critic' pragma.  I'm thinking of this just
        # like a an C<import> argument for real pragmas.
        my @no_policies = _parse_nocritic_import($pragma, $site_policies);

        # Grab surrounding nodes to determine the context.
        # This determines whether the pragma applies to
        # the current line or the block that follows.
        my $parent = $pragma->parent();
        my $grandparent = $parent ? $parent->parent() : undef;
        my $sib = $pragma->sprevious_sibling();


        # Handle single-line usage on simple statements
        if ( $sib && $sib->location->[0] == $pragma->location->[0] ) {
            my $line = $pragma->location->[0];
            for my $policy ( @no_policies ) {
                $disabled_lines->{ $line }->{$policy} = 1;
            }
            next PRAGMA;
        }


        # Handle single-line usage on compound statements
        if ( ref $parent eq 'PPI::Structure::Block' ) {
            if ( ref $grandparent eq 'PPI::Statement::Compound'
                 || ref $grandparent eq 'PPI::Statement::Sub' ) {
                if ( $parent->location->[0] == $pragma->location->[0] ) {
                    my $line = $grandparent->location->[0];
                    for my $policy ( @no_policies ) {
                        $disabled_lines->{ $line }->{$policy} = 1;
                    }
                    next PRAGMA;
                }
            }
        }


        # Handle multi-line usage.  This is either a "no critic" ..
        # "use critic" region or a block where "no critic" persists
        # until the end of the scope.  The start is the always the "no
        # critic" which we already found.  So now we have to search
        # for the end.

        my $start = $pragma;
        my $end   = $pragma;

      SIB:
        while ( my $esib = $end->next_sibling() ) {
            $end = $esib; # keep track of last sibling encountered in this scope
            last SIB
                if $esib->isa('PPI::Token::Comment') && $esib =~ $use_critic;
        }

        # We either found an end or hit the end of the scope.
        # Flag all intervening lines
        for my $line ( $start->location->[0] .. $end->location->[0] ) {
            for my $policy ( @no_policies ) {
                $disabled_lines->{ $line }->{$policy} = 1;
            }
        }
    }

    return;
}

#-----------------------------------------------------------------------------

sub _parse_nocritic_import {

    my ($pragma, $site_policies) = @_;

    my $module    = qr{ [\w:]+ }xms;
    my $delim     = qr{ \s* [,\s] \s* }xms;
    my $qw        = qr{ (?: qw )? }xms;
    my $qualifier = qr{ $qw [(]? \s* ( $module (?: $delim $module)* ) \s* [)]? }xms;
    my $no_critic = qr{ \#\# \s* no \s+ critic \s* $qualifier }xms;  ##no critic(EscapedMetacharacters)

    if ( my ($module_list) = $pragma =~ $no_critic ) {
        my @modules = split $delim, $module_list;

        # Compose the specified modules into a regex alternation.  Wrap each
        # in a no-capturing group to permit "|" in the modules specification
        # (backward compatibility)
        my $re = join q{|}, map {"(?:$_)"} @modules;
        return grep {m/$re/ixms} @{$site_policies};
    }

    # Default to disabling ALL policies.
    return qw(ALL);
}

#-----------------------------------------------------------------------------

sub _unfix_shebang {

    # When you install a script using ExtUtils::MakeMaker or Module::Build, it
    # inserts some magical code into the top of the file (just after the
    # shebang).  This code allows people to call your script using a shell,
    # like `sh my_script`.  Unfortunately, this code causes several Policy
    # violations, so we just disable it as if a "## no critic" comment had
    # been attached.

    my $doc         = shift;
    my $first_stmnt = $doc->schild(0) || return {};

    # Different versions of MakeMaker and Build use slightly different shebang
    # fixing strings.  This matches most of the ones I've found in my own Perl
    # distribution, but it may not be bullet-proof.

    my $fixin_rx = qr{^eval 'exec .* \$0 \${1\+"\$@"}'\s*[\r\n]\s*if.+;}ms; ## no critic (RequireExtendedFormatting)
    if ( $first_stmnt =~ $fixin_rx ) {
        my $line = $first_stmnt->location()->[0];
        return { $line => {ALL => 1}, $line + 1 => {ALL => 1} };
    }

    #No magic shebang was found!
    return {};
}

#-----------------------------------------------------------------------------

1;

__END__

=pod

=for stopwords pre-caches

=head1 NAME

Perl::Critic::Document - Caching wrapper around a PPI::Document.


=head1 SYNOPSIS

    use PPI::Document;
    use Perl::Critic::Document;
    my $doc = PPI::Document->new('Foo.pm');
    $doc = Perl::Critic::Document->new($doc);
    ## Then use the instance just like a PPI::Document


=head1 DESCRIPTION

Perl::Critic does a lot of iterations over the PPI document tree via
the C<PPI::Document::find()> method.  To save some time, this class
pre-caches a lot of the common C<find()> calls in a single traversal.
Then, on subsequent requests we return the cached data.

This is implemented as a facade, where method calls are handed to the
stored C<PPI::Document> instance.


=head1 CAVEATS

This facade does not implement the overloaded operators from
L<PPI::Document|PPI::Document> (that is, the C<use overload ...>
work). Therefore, users of this facade must not rely on that syntactic
sugar.  So, for example, instead of C<my $source = "$doc";> you should
write C<my $source = $doc->content();>

Perhaps there is a CPAN module out there which implements a facade
better than we do here?


=head1 CONSTRUCTOR

=over

=item C<< new($doc) >>

Create a new instance referencing a PPI::Document instance.


=back


=head1 METHODS

=over

=item C<< new($doc) >>

Create a new instance referencing a PPI::Document instance.


=item C<< ppi_document() >>

Accessor for the wrapped PPI::Document instance.  Note that altering
this instance in any way can cause unpredictable failures in
Perl::Critic's subsequent analysis because some caches may fall out of
date.


=item C<< find($wanted) >>

=item C<< find_first($wanted) >>

=item C<< find_any($wanted) >>

If C<$wanted> is a simple PPI class name, then the cache is employed.
Otherwise we forward the call to the corresponding method of the
C<PPI::Document> instance.


=item C<< filename() >>

Returns the filename for the source code if applicable
(PPI::Document::File) or C<undef> otherwise (PPI::Document).


=item C<< isa( $classname ) >>

To be compatible with other modules that expect to get a
PPI::Document, the Perl::Critic::Document class masquerades as the
PPI::Document class.


=item C<< highest_explicit_perl_version() >>

Returns a L<version|version> object for the highest Perl version
requirement declared in the document via a C<use> or C<require>
statement.  Returns nothing if there is no version statement.


=item C<< mark_disabled_lines( @policy_names ) >>

Scans the document for C<"## no critic"> pseudo-pragmas and builds
an internal table of which of the listed C<@policy_names> have
been disabled at each line.  Returns C<$self>.


=item C<< line_is_disabled($line, $policy_name) >>

Returns true if the given C<$policy_name> has been disabled for
at C<$line> in this document.  Otherwise, returns false.


=back


=head1 AUTHOR

Chris Dolan <cdolan@cpan.org>


=head1 COPYRIGHT

Copyright (c) 2006-2008 Chris Dolan.  All rights reserved.

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
