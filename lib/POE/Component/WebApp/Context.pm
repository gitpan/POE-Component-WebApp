package POE::Component::WebApp::Context;
use strict;
use warnings;
use base qw/Class::Accessor::Fast/;
use POE;
use HTTP::Status;
use HTTP::Request::Params;
use Scalar::Util qw(weaken);

__PACKAGE__->mk_accessors(qw/response request 
                             params_parsed  final_coderef 
                             dispatcher push_coderef/);

### Setup up aliases
{
    no warnings 'once';
    *resp = \&response;
	*res = \&response;
	*req = \&request;
}

sub new
{
    my $class = shift;
    my %options = @_;
    
    my $self = { request  => $options{'request'},
                 response => $options{'response'},
                 dispatcher => $options{'dispatcher'},
                 final_coderef => $options{'final_coderef'},
                 push_coderef => $options{'push_coderef'} || undef,
                 p_parsed => 0,
                 params   => undef,
                 async_calls => 0,
                 finalized => 0,
               };
    
    bless $self, $class;
        
    return $self;
}


sub stripped
{
    my $self = shift;
    return { response   => $self->{'response'}, 
             finalized  => $self->{'finalized'},
           };
}

sub redirect
{
   my ( $self, $location) = @_; 
   $self->response->header( Location => $location );
   $self->response->code( RC_SEE_OTHER );
   return $self->finalize;
}

sub params
{
    my $self = shift;
    if ( $self->params_parsed )
    {
        return $self->{'params'};
    }
    else
    {
        my $parser = HTTP::Request::Params->new({
                  	req => $self->request,
               	});
        $self->{'params'} = $parser->params;
        $self->params_parsed(1);
        return $self->{'params'};
    }
}

sub sf
{
    my ($self, $ipath, $args) = @_;
    
    die "I need an internal path to sync forward to.\n"
        unless defined $ipath;
        
    return $self->{'dispatcher'}->_sync_forward( $self, $ipath, $args);
}

sub af
{
    my ($self, $ipath, $args, $back_ref) = @_;
    
    die "I need an internal path to a-sync forward to.\n"
        unless defined $ipath;
        
    return $self->{'dispatcher'}->_async_forward( $self, $ipath, $args, $back_ref);
}

sub forward
{
    my ($self, $ipath, $args) = @_;
    
    die "I need an internal path to forward to.\n"
        unless defined $ipath;
        
    return $self->{'dispatcher'}->_smart_forward( $self, $ipath, $args);
}

sub param
{
    my ($self, $key) = @_;
    return $self->params->{$key};
}

sub s_forward
{
    my $self = shift;
}

sub r_wait
{
    my ($self, @requests) = @_;
    until(scalar( grep { $_->is_ready } (@requests) ) == scalar @requests)
    {
        POE::Kernel->run_one_timeslice;
    }
}

sub finalize
{
    my $self = shift;
    return 
        if $self->{'finalized'}; 
    
   	$self->final_coderef->();
    $self->{'finalized'} = 1;
}

1;
