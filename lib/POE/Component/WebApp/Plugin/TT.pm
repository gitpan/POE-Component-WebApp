package POE::Component::WebApp::Plugin::TT;
use strict;
use warnings;
use base qw/POE::Component::WebApp::Plugin/;
use Template;

my $tt = Template->new();

sub initialize
{
    my ($class) = @_;
    return sub { return process_template(@_) };
}


sub process_template
{
}

1;
