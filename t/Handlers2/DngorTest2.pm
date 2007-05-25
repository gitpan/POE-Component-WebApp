package DngorTest2;
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


sub something : Exposed
{
    my ($class, $args) = @_;
### Make sure everything in root namespace will give us /method
### aswell as /dngortest/method
    $class->c->sf('/dngortest/spin');
    $class->c->resp->code(200);
    $class->c->finalize();
}

sub something_else : Exposed
{
    my ($class, $args) = @_;
### Make sure everything in root namespace will give us /method
### aswell as /dngortest/method
    $class->c->af('/dngortest/spin');
    $class->c->af('/dngortest/spin1');
    $class->c->af('/dngortest/spin2');
    $class->c->resp->code(200);
    $class->c->finalize();
}

sub test_forward : Exposed
{
    my ($class, $args) = @_;
    $class->c->af('/dngortest/spin');
    $class->c->af('/dngortest/spin1');
    $class->c->af('/dngortest/spin2');
    $class->c->resp->code(200);
    $class->c->finalize();
}

sub spin : Async('soft')
{
    my ($class, $args) = @_;
    $class->c->resp->content('This is coming from spin.');
}

sub spin1 : Async
{
    my ($class, $args) = @_;
    $class->c->resp->content( $class->c->resp->content . '  This is coming from spin 1.');
}

sub spin2 : Async
{
    my ($class, $args) = @_;
    $class->c->resp->content( $class->c->resp->content . '  This is coming from spin 2.');
}

1;
