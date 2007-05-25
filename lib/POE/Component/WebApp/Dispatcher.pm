package POE::Component::WebApp::Dispatcher;
use strict;
use warnings;
use base qw/Class::Accessor::Fast/;
#use KOE::Authentication::ACL qw/protected_path/;
use POE;
use POE::Component::WebApp::Util::Attr qw(fork_this);
use POE::Component::WebApp::Dispatcher::Result;
use POE::Component::WebApp::Dispatcher::Result::Deferred;
use Scalar::Util qw(refaddr);

use constant DEFAULT_METHOD => 'called_or_default';
use constant FORK => 1;

__PACKAGE__->mk_accessors(qw/module_dir dmo root_namespace 
                             restful session_id adapter my_address/);

sub new
{
    my $class = shift;
    my %options = @_;
    my $context = shift;
    
    my $self = { root_namespace => $options{'root_namespace'},
                 module_dir     => $options{'handler_dir'},
                 restful        => $options{'restful'} || 0,
                 dmo            => $options{'dmo'} || [DEFAULT_METHOD],
                };
    
### Set up address 
    $self->{'my_address'} = refaddr $self;
   
    bless $self, $class;
    
### Run an initializations that are needed
    $self->_initialize( %options );
    
### Create and assign session and start up processing
    $self->{'session_id'} = POE::Session->create
    (
        inline_states  => { _start      => sub { $_[KERNEL]->alias_set( $self->{'my_address'} ),
                                                 $_[KERNEL]->sig(CHLD => 'reap_action'),
                                               },
                            reap_action => \&reap_forked_action,
                          }, 
        object_states  => [ $self  => { process_path => '_process_path', 
                                        execute_code => '_execute_code', 
                                      },
                          ]
    )->ID;
    
    return $self;
}

sub _initialize
{
    die "ABSTRACT METHOD\n";
}

sub _process_path
{
    die "ABSTRACT METHOD\n";
}

sub _execute_code
{
    my ($self, $code_def) = @_[OBJECT, ARG0];
    
    if( fork_this $code_def->{'code'} )
    {
        $self->_execute_action( $code_def->{'context'}, 
                            	$code_def->{'code'}, 
                            	$code_def->{'class'}, 
                            	$code_def->{'method'}, 
                            	$code_def->{'args'} || [],
                            	$code_def->{'result'},
                            	FORK
                           	  );
    }
    else
    {
        $self->_execute_action( $code_def->{'context'}, 
                            	$code_def->{'code'}, 
                            	$code_def->{'class'}, 
                            	$code_def->{'method'}, 
                            	$code_def->{'args'} || [],
                            	$code_def->{'result'},
                           	  );
    }
                           
    $code_def->{'context'}->{'async_calls'}--;
}

sub _async_forward
{
    my ($self, $context, $ipath, $args, $back_ref) = @_;
    
    my $d_table = $self->dispatch_table;
    
    my $result = POE::Component::WebApp::Dispatcher::Result::Deferred->new( { callbacks => $back_ref->{'callbacks'},
                                                                              postbacks => $back_ref->{'postbacks'},
                                                                              err_backs => $back_ref->{'errbacks'},
                                                                              orig_args => $args || [],
                                                                            },
                                                                          );
    
    if( my $code_def = $d_table->{'private'}->{$ipath} )
    {
        _queue_action( $self->{'session_id'}, 
                       { context => $context, 
                         args => $args,
                         result => $result,
                         %$code_def,
                       },
                     );
    }
    else
    {
        warn "Internal path  $ipath not found.\n";
    }
    
    return $result;
}

sub _sync_forward
{
    my ($self, $context, $ipath, $args) = @_;
    
    my $d_table = $self->dispatch_table;
    
    my $result = POE::Component::WebApp::Dispatcher::Result->new();
    
    if( my $code_def = $d_table->{'private'}->{$ipath} )
    {
        $self->_execute_action( $context, $code_def->{'code'}, $code_def->{'class'}, $code_def->{'method'}, $args, $result);
    }
    else
    {
        die "Internal path  $ipath not found.\n";
    }
    
    return $result;
}

sub _execute_action
{
    my ( $self, $context, $code_ref, $module, $method_name, $arg_ref, $result, $fork) = @_;
    my ($action, $action_class);
    #warn Dumper( @_ );
    #KOE::Log::info("Loading: $module\->$method_name for execution.");
    if( $fork )
    {
        $action_class = 'POE::Component::WebApp::Action::Fork';
    }
    else
    {
        $action_class = 'POE::Component::WebApp::Action';
    }
    
    $action = $action_class->new
              ({  method_name => $method_name,
                  module      => $module,
                  code_ref    => $code_ref,
                  context     => $context,
                  args        => $arg_ref || [],
                  result      => $result,
              });
                  
    $action->execute;
}

sub _queue_action
{
    my ($session_id, $call_args) = @_;
    $call_args->{'context'}->{'async_calls'}++;
    POE::Kernel->post( $session_id, 'execute_code', $call_args );
}

sub _check_coderef
{
    my ( $self, $module, $method) = @_;
    #KOE::Log::debug("check for method: $method in module: $module.");
    $module && $method ?  return $module->can($method) 
                       : return undef;
}

sub reap_forked_action
{
### May want to do something with this at a later date
    #warn "REAPER\n";
}


=pod

=head1 NAME

POE::Component::WebApp::Dispatcher - PoCo-WebApp Dispatcher base class.

=head1 DESCRIPTION

 PoCo-WebApp Dispatcher base class.  Sub-class this if you'd like to change
 the way requests are dispatched by your webapp.

=cut

1;