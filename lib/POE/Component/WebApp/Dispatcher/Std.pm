package POE::Component::WebApp::Dispatcher::Std;
use strict;
use warnings;

use base qw/POE::Component::WebApp::Dispatcher/;
use File::Find;
use Text::TabularDisplay;
use Module::Info::File;
use Devel::InnerPackage qw(list_packages);
use POE;

use constant DEFAULT_METHOD => 'called_or_default';

### Each Preload Dispatcher has it's own dispatch_table
### The key is it's memory address
our %dispatch_table;

sub DESTROY
{
    my $self = shift;
    delete $dispatch_table{ $self->my_address }; 
}

sub dispatch_table
{
    my $self = shift;
    return $dispatch_table{ $self->my_address };
}

sub _initialize
{
    my ($self, %options) = @_;
### Build slot in dispatch table
    my $addy = $self->my_address;
    
    $dispatch_table{ $addy } = {};
    
### Load modules
    find({ wanted => sub { _load_module( $dispatch_table{ $addy }, $self->{'root_namespace'} ) }, 
           no_chdir => 1 }, 
           $self->{'module_dir'},
        );
}

sub _load_module
{
    if( -f $_ and $_ =~ /pm$/)
    {
       	eval
       	{
       		require $_;
        ### TODO test the inner package stuff
       		my $mod_name = Module::Info::File->new_from_file( $_ )->name;
       		
       		my @inner_packages = list_packages( $mod_name );
       		
        ### Make sure we get the inner packages if there are any defined	
       		for my $package ($mod_name, @inner_packages)
       		{
                $package->_register_dispatches( shift, shift)
                	if $package->isa('POE::Component::WebApp::Controller');
       		}
       	};
       	warn "Failed to load: $_ because: $@\n"
       	    if $@;
   	}
}

sub _process_path
{
    my ( $self, $context) = @_[OBJECT, ARG0];
    my ($path_info, $module, @args, @path, $code_ref, $method);
    
    $path_info = $context->request->uri->canonical->path;
    
### TODO need to revisit this, i'm sure there is a cleaner way to do this path stuff
    if( $path_info eq '/' )
    {
        @path = ('/');
    }
    else
    {
        $path_info =~ s|/$||;
    ### Split this out
        @path = split '/', $path_info;
    }
    
    my $found = 0;
    my $add = $self->my_address;
    
### Search for path
    do
    {
        my $path = (join '/', @path) || '/';
        #KOE::Log::debug("Searching for Module: $module");
        #warn("Searching for path: $path\n");
    ### Check to see if we can load the module
        if( exists $dispatch_table{ $add }->{'exposed'}->{ $path } )
        {
            #warn "found path: $path with args: @args\n";
            $code_ref = $dispatch_table{ $add }->{'exposed'}->{ $path }->{'code'};
            $module = $dispatch_table{ $add }->{'exposed'}->{ $path }->{'class'};
            $method = $dispatch_table{ $add }->{'exposed'}->{ $path }->{'method'};
            
            $found = 1;
        }
        else
        {
            #warn "did not find path: $path\n";
            unshift @args, pop @path;
        }
    }while( !$found && @path);
    
    if( $found )
    {
    ### Get DMO table
        my $method_order = $self->dmo; 
    
        for my $method_type (@$method_order)
        {
            if( $method_type eq DEFAULT_METHOD )
            {
               $self->_execute_action($context, $code_ref, $module, $method, \@args);
            }
            else
            {
                if ( $method and $code_ref = $self->_check_coderef($module, $method_type))
                {
                    $self->_execute_action($context, $module, $method_type, \@args);
                }
            }
        }
        
    } 
    else ### Return a not found
    {
        $context->res->content("Handler not found for $path_info.");
        $context->res->code(404);
        $context->finalize();
    }
}

=pod

=head1 NAME

POE::Component::WebApp::Dispatcher::Std - PoCo-WebApp's standard(default) dispatcher.

=head1 DESCRIPTION

 PoCo-WebApp standard dispatcher.  The usual uri-to-method translation.

=cut

1;
