package DngorTest::Dngorish;
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

sub testargforward : Exposed
{
    my ($class) = @_;
    my $content = $class->c->resp->content;
    $class->c->sf('/dngortest/index', [qw/arg3 arg4/]);
}

sub hotness : Exposed('hello')
{
    my ($class, $args) = @_;
    
### TODO i'm almost 100% there are issues with doing things this way
    $class->c->resp->content('Hello there.');
    $class->c->resp->code(200);
    $class->c->finalize();
}

sub asyncfork : Exposed
{
    my ($class, $args) = @_;
### Make sure everything in root namespace will give us /method
### aswell as /dngortest/method
    my $r1 = $class->c->af('/dngortest/dngorish/spin', { postbacks => ['/dngortest/postback1'],
                                                callbacks => [],
                                                err_backs => [],
                                              }
                          );
    my $r2 = $class->c->af('/dngortest/dngorish/spin1');
    my $r3 = $class->c->af('/dngortest/dngorish/spin2');
    $class->c->r_wait($r1, $r2, $r3);
    #$class->c->r_wait($r2, $r3);
    $class->c->resp->content('This should come last.  ' . $r1->value->[0] . ' ' . $r2->value->[0] . ' ' . $r3->value->[0]);
    #$class->c->resp->content('This should come last.  ');
    $class->c->resp->code(200);
    $class->c->finalize();
    #return ('something','someone');
}

sub spin : Async('Fork')
{
    my ($class, $args) = @_;
    #$class->c->resp->content( $class->c->resp->content . 'This is coming from spin.');
    return 'spin';
}

sub spin1 : Async('Fork')
{
    my ($class, $args) = @_;
    #$class->c->resp->content( $class->c->resp->content . '  This is coming from spin 1.');
    return 'spin1';
}

sub spin2 : Async('Fork')
{
    my ($class, $args) = @_;
    #$class->c->resp->content( $class->c->resp->content . '  This is coming from spin 2.');
    return 'spin2';
}

1;