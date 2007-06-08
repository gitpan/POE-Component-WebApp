package POE::Component::WebApp::Action;

use strict;
use warnings;
use base qw/Class::Accessor::Fast/;

__PACKAGE__->mk_accessors(qw/method_name module code_ref context args result/);

sub new
{
    my $class = shift;
    my $self = shift;
    
    bless $self, $class;
    return $self;
}

sub execute
{
    my $self = shift;
    my @rv;
    eval
    {
    ### NOTE this has to stay a call to a the code_ref accessor subroutine
    ### this is being used instead of {'code_ref'} so that the Devel::Caller
    ### routine in the Controller package to get the context object.
        @rv = $self->code_ref->( $self->{'module'}, $self->{'args'} ); 
    };
    
    if($@)
    {
        warn "There was an error while I was executing: $@\n";
        if( $self->{'result'} )
        {
            $self->{'result'}->{'has_error'} = 1;
            $self->{'result'}->{'is_ready'} = 1;
        #### Combine a path that the error happened from for the error message
            $self->{'result'}->{'error'} = $@;
        }
    }
    else
    {
        if( $self->{'result'} )
        {
            $self->{'result'}->{'is_ready'} = 1;
            $self->{'result'}->{'value'} = \@rv;
        }
    }
    
    $self->process_result
        if $self->{'result'};
}

sub process_result
{
    my $self = shift;
    if( $self->{'result'}->isa('POE::Component::WebApp::Dispatcher::Result::Deferred') )
    {
    ### If there is an error dispatch the err_backs
    ### TODO probably need some error trapping here to make sure they dont pass
    ### in a different type of reference
        if( $self->{'result'}->{'has_error'})
        {
            my $err_backs = $self->{'result'}->err_backs; 
            return
                unless $err_backs;
            if( ref $err_backs and ref $err_backs eq 'ARRAY' )
            {
                $self->{'context'}->sf( $_ ) for (@$err_backs);
            }
            else
            {
                $self->{'context'}->sf( $err_backs );
            }
        }         
        else
        {
        	for ([callbacks => 'sf'], [postbacks => 'af'])
        	{
        	    my $method = $_->[0];
        	    my $dispatch = $_->[1];
        	    my $backs = $self->{'result'}->$method;
        	    return
        	       unless $backs;
        	       
                if( ref $backs and ref $backs eq 'ARRAY' )
            	{
                	$self->{'context'}->$dispatch( $_, $self->{'result'}) for (@$backs);
            	}
            	else
            	{
                	$self->{'context'}->$dispatch( $backs, $self->{'result'});
            	}
            }
        }
    }
}

1;
