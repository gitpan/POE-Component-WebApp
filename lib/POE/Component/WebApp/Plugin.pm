package POE::Component::WebApp::Plugin;
use strict;
use warnings;


sub initialize
{
    die "ABSTRACT METHOD.\n";
}


sub plugin_key
{
    my $class = shift;
    return (split /\::/, $class)[-1];
}

1;
