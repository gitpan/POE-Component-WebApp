package POE::Component::WebApp::Adapter::SimpleHTTP;
use strict;
use warnings;
use POE;

use base qw/POE::Component::WebApp::Adapter/;


sub _initialize
{
    my $self = shift;
    my %options = @_;
    
    die "I need the alias/session id of the SimpleHTTP Server to work."
        unless $options{'simple_alias'};
        
    $self->{'simple_alias'} = $options{'simple_alias'};
}

sub build_res
{
    my $self = shift;
    return $_[ARG1];
}

sub build_req
{
    my $self = shift;
    return $_[ARG0];
}

sub build_final_coderef
{
    my $self = shift;
    my $response = $self->build_res( @_ );
    my $kernel = $_[KERNEL];
    return sub { $kernel->call( $self->{'simple_alias'}, 'DONE', $response) };
}

sub build_push_coderef
{
    my $self = shift;
    return undef;
}

1;
