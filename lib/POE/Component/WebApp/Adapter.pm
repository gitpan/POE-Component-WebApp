package POE::Component::WebApp::Adapter;
use strict;
use warnings;

sub new
{
    my $class = shift;
    my $self = {};
    bless $self, $class;
    
    $self->_initialize( @_ );
    
    return $self;
}

sub _initialize
{
    die "ABSTRACT CLASS\n";
}

sub build_res
{
    die "ABSTRACT CLASS\n";
}

sub build_req
{
    die "ABSTRACT CLASS\n";
}

sub build_final_coderef
{
    die "ABSTRACT CLASS\n";
}

sub build_push_coderef
{
    die "ABSTRACT CLASS\n";
}

=pod

=head1 NAME

POE::Component::WebApp::Adapter - Base class for POE::Component::WebApp Adapters

=head1 SYNOPSIS
 
 my $adapter = POE::Component::WebApp::Adapter::<ADAPTER TYPE>;
 my $dispatcher = POE::Component::WebApp->new( adapter => $adapter,
                                                   ...
                                                 );

=head1 DESCRIPTION

 Adapters allow the L<POE::Component::WebApp> and it's context objects to dispatcher URIs
 for different servers.  The Adapters turn it into a base form that the Dispatcher recognizes.

=cut

1;