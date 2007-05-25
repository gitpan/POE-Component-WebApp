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
}

1;
