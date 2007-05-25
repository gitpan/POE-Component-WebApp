package DngorTest2::Dngorish;
use strict;
use warnings;
use base qw/POE::Component::WebApp::Controller/;

sub index : Exposed
{
    my ($class, $args) = @_;
    
    $class->c->resp->code(200);
    $class->c->resp->content('this is index of ' . __PACKAGE__ );
    $class->c->finalize();
}

sub hot_thing : Exposed('/dngortest/dngorish/hotness')
{
    my ($class, $args) = @_;
    
    $class->c->resp->content('It is hot in here.');
    $class->c->resp->code(200);
    $class->c->finalize();
}

sub hot_redirect : Exposed('/dngortest/dngorish/redirect')
{
    my ($class, $args) = @_;
    $class->c->resp->content('I am going to redirect.');
    
    $class->c->resp->code(200);
    $class->c->finalize();
}

sub imdirected  : Exposed('/dngortest/dngorish/imdirected')
{
    my ($class) = @_;
    my $content = $class->c->resp->content;
    $class->c->resp->content($content . '  This has been redirected.');
    $class->c->resp->code(200);
}

sub hotness : Exposed('hello')
{
    my ($class, $args) = @_;
    
    $class->c->resp->content('Hello there.');
    $class->c->resp->code(200);
    $class->c->finalize();
}

1;
