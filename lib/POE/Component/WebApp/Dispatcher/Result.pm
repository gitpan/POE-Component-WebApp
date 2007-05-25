package POE::Component::WebApp::Dispatcher::Result;
use strict;
use warnings;

use base qw/Class::Accessor::Fast/;

__PACKAGE__->mk_accessors(qw/has_error error value is_ready/);


sub new
{
    my $class = shift;
    my $opts = shift || {};
    my $self = { value     => undef,
                 has_error => 0,
                 error     => undef,
                 is_ready  => 0,
                 %$opts
               };
               
    bless $self, $class;
    return $self;
}


=pod

=head1 NAME

POE::Component::WebApp::Dispatcher::Result - PoCo-WebApp Dispatcher result class.

=head1 DESCRIPTION

 PoCo-WebApp dispatcher result class.  All forward() calls, synchronous and asynchronous,
 return PoCo-WebApp dispatch result object's.  This allows for a consistent way of 
 handling both forward types.  This is the synchronous base class, the deferred result
 class is a subclass of this.

=cut

1;
