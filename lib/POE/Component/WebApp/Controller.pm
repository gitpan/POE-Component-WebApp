package POE::Component::WebApp::Controller;
use strict;
use warnings;
use attributes;
use URI;
use Devel::Caller qw(caller_vars);
use POE::Component::WebApp::Util::Attr qw(split_attr);
use Class::Inspector;

use constant CLASS => 1;
use constant METHOD => 2;
use constant CODE_REF => 3;

my $handler_table = { 
                        Exposed => \&_path_handler,
                    };

our %attrib_table;

sub MODIFY_CODE_ATTRIBUTES 
{
    my ( $class, $code_ref, @attrs ) = @_;
    $attrib_table{ $code_ref } = \@attrs;
    return ();
}

sub c
{
    my $vars = caller_vars(1,0); 
    return $$vars->context;
}

sub _register_dispatches
{
    my ($class, $d_table, $root_namespace) = @_;
    
    my $methods = Class::Inspector->methods( $class, 'public', 'expanded');
    
    #warn "\n Here Registing dispatch for $class d_Table : $d_table  namespace: $root_namespace\n";
    for my $m_info (@$methods)
    {
        my $class = $m_info->[CLASS];
        
        unless($class eq __PACKAGE__ )
        {
            #warn "SOME: $m_info->[1] $m_info->[2] $m_info->[3] \n";
            my $code = $m_info->[CODE_REF];
            my $attrs = $attrib_table{ $code };
            my $method = $m_info->[METHOD];
            
            my $options = {  class => $class, 
                             method => $method, 
                             code_ref => $code, 
                             root_namespace => $root_namespace,
                          };
            
        ### If we have attribs handle the ones we have a handler for 
            if( $attrs and scalar @$attrs )
            {
                for (@$attrs)
                {
                    my ($type, $args) = split_attr( $_ ); 
                    #warn "Attrib type: $type \n";
                    
                    $handler_table->{ $type }->( {  %$options,
                                                    args => $args,
                                                    d_table => $d_table,
                                                 } 
                                               )
                        if exists $handler_table->{ $type };
                }
            }
            
            my $private_path = _local_handler( $options ); 
            
            _add_to_table( $options, $d_table, $private_path, 'private'); 
        }
    }
}

sub _colon_to_slash
{
    my $class = shift;
    return 
        unless defined $class;
    $class =~ s|\::|/|g;
    return lc $class;
}

sub _processed_path
{
    my $options = shift;
    my $debug = shift || 0;
    my $con_class = _colon_to_slash( $options->{'class'} );
    my $r_class = _colon_to_slash( $options->{'root_namespace'} );
    
    print "con_class: $con_class and rclass: $r_class method: $options->{'method'}"
        if $debug;
    $con_class =~ s|$r_class||
        if defined $r_class;
    print "con_class: $con_class\n"
        if $debug;
    
    return $con_class;
}

sub _local_handler
{
    my $options = shift;
    my $path = _processed_path( $options ) . lc "/$options->{'method'}";
    return $path;
}

sub _strip_root_namespace
{
    my ($root, $class_name) = @_;
    $root = _colon_to_slash( $root );
}

sub _path_handler
{
    my $options = shift;
    my ($uri, $path);
    my $dispatch_table = $options->{'d_table'};
    
    if( $options->{'args'} )
    {
        my $user_path = $options->{'args'};
        if($user_path =~ m|^/| )
        {
            $path = $user_path;
        }
        else
        {
            $path = _processed_path( $options ) . '/' . "$user_path";
            $path = "/$path"
                unless $path =~ m|^/|;
        }
    }
    else
    {
        if( $options->{'method'} eq 'index' )
        {
            $path = _processed_path( $options );
            $path = "/$path"
                unless $path =~ m|^/|;
        }
        else #### Standard expose
        {
            $path = _processed_path( $options ) . "/$options->{'method'}";
        }
    }
    
   _add_to_table( $options, $dispatch_table, $path, 'exposed'); 
}

sub _add_to_table
{
    my ($options, $dispatch_table, $path, $type) = @_;
    #warn "ADD PATH: $path\n";
    
    my $d_path = lc( URI->new( $path, 'http' )->canonical->path );
    
    $dispatch_table->{ $type }
                   ->{ $d_path } = { code => $options->{'code_ref'}, 
                                     method => $options->{'method'}, 
                                     class => $options->{'class'},
                                   }; 
                   
### Do I need to add another for the root namespace
    #if( $type eq 'exposed' 
        #and $options->{'root_namespace'}
        #and $options->{'class'} eq $options->{'root_namespace'} )
    #{
        ##my $root_namespace = lc $options->{'root_namespace'};
        ##$d_path =~ s|^/$root_namespace/?|/|;
        ##$dispatch_table->{ $type }
                       ##->{ $d_path } = { code => $options->{'code_ref'}, 
                                         ##method => $options->{'method'}, 
                                         ##class => $options->{'class'},
                                       ##}; 
    #}
}

1;
