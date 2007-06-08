package DngorTest;
use strict;
use warnings;
use base qw/POE::Component::WebApp::Controller/;

sub index : Exposed
{
    my ($class, $args) = @_;
    
    $class->c->resp->code(200);
    $class->c->resp->content('this is index of ' . __PACKAGE__);
    $class->c->resp->content( $class->c->resp->content . " @{$args}" )
        if scalar @$args;
    $class->c->finalize();
}

sub something : Exposed
{
    my ($class, $args) = @_;
### Make sure everything in root namespace will give us /method
### aswell as /dngortest/method
    my $r1 = $class->c->sf('/add_these', [ 1,2,3 ]);
    $class->c->resp->content('This is coming from something, result was ' . (@{$r1->value})[0] . '.');
    $class->c->resp->code(200);
    $class->c->finalize();
}

sub add_these
{
    my ($class, $args) = @_;
    my $result = 0;
    $class->c->resp->content('This is coming from test_arg_pass_forward.');
    ( $result += $_ ) for (@$args);
    return $result;
}

sub echo : Exposed
{
    my ($class, $args) = @_;
    my $content = $class->c->resp->content;
    for(@$args)
    {
        $content ?  ($content .= " Arg $_")
                 :  ($content = "Arg $_");
    }
    $class->c->resp->content( $content );
    $class->c->resp->code(200);
    $class->c->finalize();
}

sub async_forward : Exposed('/asyncforward')
{
    my ($class, $args) = @_;
### Make sure everything in root namespace will give us /method
### aswell as /dngortest/method
    my $r1 = $class->c->af('/spin', undef, { postbacks => ['/postback1'],
                                             callbacks => [],
                                             err_backs => [],
                                           }
                          );
    my $r2 = $class->c->af('/spin1');
    my $r3 = $class->c->af('/spin2');
    $class->c->r_wait($r1, $r2, $r3);
    $class->c->resp->content( $class->c->resp->content . '  This should come last.');
    $class->c->resp->code(200);
    $class->c->finalize();
}

sub postback1
{
    my ($class, $args) = @_;
    warn "we are here in POSTBACK ONE\n";
}

sub postback2
{
    my ($class, $args) = @_;
    warn "we are here in POSTBACK TWO\n";
}

sub testforward : Exposed
{
    my ($class, $args) = @_;
    my $r1 = $class->c->af('/spin', [1,2,3]);
    my $r2 = $class->c->af('/spin1');
    my $r3 = $class->c->af('/spin2');
    $class->c->r_wait($r1, $r2, $r3);
    $class->c->resp->code(200);
    $class->c->finalize();
}

sub spin : Async
{
    my ($class, $args) = @_;
    $class->c->resp->content( $class->c->resp->content . 'This is coming from spin.');
    return 'spin';
}

sub spin1 : Async
{
    my ($class, $args) = @_;
    $class->c->resp->content( $class->c->resp->content . '  This is coming from spin 1.');
    return 'spin1';
}

sub spin2 : Async
{
    my ($class, $args) = @_;
    $class->c->resp->content( $class->c->resp->content . '  This is coming from spin 2.');
    return 'spin2';
}

1;
