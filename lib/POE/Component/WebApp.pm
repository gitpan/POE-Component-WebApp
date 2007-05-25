package POE::Component::WebApp;
use strict;
use warnings;
use base qw/Class::Accessor::Fast/;
use POE;
use POE::Component::WebApp::Context;
use POE::Component::WebApp::Action;
use POE::Component::WebApp::Action::Fork;
use POE::Component::WebApp::Util qw(has_attrib);
use Scalar::Util qw(refaddr);
use Module::Pluggable::Dependency;

use constant DEFAULT_METHOD => 'called_or_default';

__PACKAGE__->mk_accessors(qw/module_dir dmo root_namespace 
                             restful session_id adapter my_address/);

our $VERSION = '0.01_01';

sub new
{
    my $class = shift;
    my %options = @_;
    my $context = shift;
    
    my $self = { adapter        => $options{'adapter'},
                 dispatch_type  => $options{'dispatch_type'} || 'Std',
                 dispatcher     => undef,
                 session_id     => undef,
                };
    
### If we don't have an adapter die or adapter isn't what we need
    die "Must have an adapter to work."
        unless defined $self->{'adapter'};
        
    die "Must have a Dispatcher adapter to work."
        unless ref $self->{'adapter'} 
               and $self->{'adapter'}->isa('POE::Component::WebApp::Adapter');

### Set up address 
    $self->{'my_address'} = refaddr $self;
    
    bless $self, $class;
    
### Create and assign session and start up processing
    $self->{'session_id'} = POE::Session->create
    (
        inline_states  => { _start => sub { $_[KERNEL]->alias_set( $self->{'my_address'} ) } }, 
        object_states  => [ $self  => { DISPATCH     => '_dispatch' },
                          ]
    )->ID;
    
### Create and assign dispatcher session and start up processing
    eval
    {
        my $d_class = "POE::Component::WebApp::Dispatcher::$self->{'dispatch_type'}";
        warn "Loading app with dispatcher: $d_class\n";
        eval "require $d_class;";
        die "Could not load dispatcher class $d_class because $@"
            if $@;
        eval
        {
             $self->{'dispatcher'} = $d_class->new( %options );
        };
        
        die "Could not instantiate dispatcher class $d_class because $@"
            if $@;
    };
    
### Initialize plugins
    $self->init_plugins( $self->{'config'}->{'plugins'} );
    
    return $self;
}

sub _dispatch
{
    my ( $self, $kernel, $request, $response) = @_[OBJECT, KERNEL, ARG0, ARG1];
    my $adap = $self->adapter;
    
    my $context = POE::Component::WebApp::Context->new( response => $adap->build_res( @_ ),
                                                        request  => $adap->build_req( @_ ),
                                                        final_coderef => $adap->build_final_coderef( @_ ),
                                                        push_coderef => $adap->build_push_coderef( @_ ),
                                                        dispatcher => $self->{'dispatcher'},
                                                      );
                                                          
### Start Dispatch Process 
    $kernel->post( $self->{'dispatcher'}->session_id, 'process_path', ($context));
}

sub init_plugins
{
    my ($self, $plugins) = @_;
           
    my @plugins = $self->plugins;
    
    for (@plugins)
    {
        warn "PLUGINS: @plugins \n";
        #my $code_ref = $_->initialize;
        #%plugin_map{ $addy } = ( %plugin_map, $_->plugin_key, $code_ref);
    }
}

=pod

=head1 NAME

POE::Component::WebApp - An asynchronous(POE) HTTP framework for building web applications.

=head1 DESCRIPTION

 PoCo-WebApp is an asynchronous(POE) HTTP framework built with simplicity in mind.
 Asynchronous frameworks are capable of handling synchronous framework duties, but excel
 in distributed systems, an example of this would be a request to an application that 
 queries multiple other systems(ie. Webservices, partitioned dbases, etc.) to produce a 
 response.
 In a distributed system where each call may make up to six other calls each taking ~1 
 second, a synchronous framework would take 6 seconds before calculating and returning a
 response whereas an asynchronous system would take 1 seconds.  Of course harnessing
 the full power of this requires a slight shift in the way you think when designing your
 applications.
 
 Poco-WebApp supports different connections formats through the use of through the use 
 of L<POE::Component::WebApp::Adapter>s.  Currently slated adapters is for 
 L<POE::Component::FastCGI>, L<POE::Component::Server::SimpleHTTP> and L<Sprocket>.
 
 This module is in a developmental state.  Certain parts of the API may be changed as other
 parts mature.  The majority of the documentation is with the tests, this will be a priority
 once the API solidifies.

=cut

1;