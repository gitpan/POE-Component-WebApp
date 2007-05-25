package POE::Component::WebApp::Action::Fork;
use strict;
use warnings;
use base 'POE::Component::WebApp::Action';
use POE qw(Wheel::Run Filter::Reference);
use Scalar::Util qw(refaddr);
our $Debug = 0;

sub execute
{
    my $self = shift;
    
### Create necessary events using address so it's unique
    my $addy = refaddr $self;
    my $stdout_e = "action_stdout_$addy"; 
    my $stderr_e = "action_stderr_$addy"; 
    my $error_e = "action_error_$addy"; 
    my $close_e = "action_close_$addy"; 
    
    my %events = ($stdout_e => sub { handle_stdout( $self, @_ ) }, 
                  $stderr_e => sub { handle_error( $self, @_) }, 
                  $error_e => sub { handle_io_error( $self, @_) }, 
                  $close_e => sub { cleanup( $self, @_) },
                 );
    while(my($event, $code_ref) = each %events)
    {
        warn "Adding state: $event forked action with addy: $addy"
            if $Debug;
        POE::Kernel->state( $event, $code_ref);
    } 
    
    $self->{'registered_events'} = [ keys %events ];
    warn "Forking off wheel for calling method: $self->{'method_name'} in module: $self->{'module'} with addy: $addy\n"
        if $Debug;
    
    my $wheel = POE::Wheel::Run->new(
    # Set the program to execute, and optionally some parameters.
    	Program     => sub { my @rv = $self->code_ref->( $self->{'module'}, $self->{'args'} );
    	                     my $filter = POE::Filter::Reference->new();
    	                     my $s_context = $self->{'context'}->stripped;
                             my $data = $filter->put( [ { %$s_context, result => \@rv } ] );
                             print STDOUT @$data;
    	                    },

    	StdoutEvent => $stdout_e, # Received data from the child's STDOUT.
    	StderrEvent => $stderr_e, # Received data from the child's STDERR.
    	ErrorEvent  => $error_e,  # An I/O error occurred.
    	CloseEvent  => $close_e,  # Child closed all output handles.

    # Shorthand to set StdinFilter and StdoutFilter together.
        StdioFilter => POE::Filter::Reference->new(),    # Or some other filter.
    );
    
### Grab session and save wheel so that it doesn't run away
    my $sess_heap = POE::Kernel->get_active_session->get_heap;
    
    $sess_heap->{"action_$addy"} = $wheel;
}

sub handle_stdout
{
    my $self = shift;
    my ($result) =  $_[ARG0];
    
    my $addy = refaddr $self;
    
### Use response from fork incase they didn't heed our warning
    #$self->{'context'}->{'response'} = $s_context->{'response'};
    $self->{'result'}->{'value'} = $result->{'result'};
    $self->{'result'}->{'is_ready'} = 1;
    $self->{'context'}->finalize
        if $result->{'finalized'};
}

sub handle_error
{
    my $self = shift;
    my $error = $_[ARG0];
    my $addy = refaddr $self;
    warn "STDERR for method: $self->{'method_name'} in module: $self->{'module'} with addy: $addy, error is: $error\n"
        if $Debug;
}

sub handle_io_error
{
    my $self = shift;
    my $error = $_[ARG0];
    my $addy = refaddr $self;
    warn "IOERR for method: $self->{'method_name'} in module: $self->{'module'} with addy: $addy, error is: $error\n"
        if $Debug;
}

sub cleanup
{
    my $self = shift;
    my $addy = refaddr $self;
    warn "CLEANING UP WHEEL for $self with addy: $addy\n"
        if $Debug;
    my $events = $self->{'registered_events'};
### We need to unregister events
    for (@$events)
    {
        warn "Removing state: $_ for forked action with addy: $addy"
            if $Debug;
        POE::Kernel->state( $_ );
    } 
### Destroy the wheel
    my $sess_heap = POE::Kernel->get_active_session->get_heap;
    delete $sess_heap->{'action_$addy'};
}

1;