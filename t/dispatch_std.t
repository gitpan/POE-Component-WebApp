#!/usr/bin/perl -w

use strict;
use warnings;
#use Test::More tests => 12;
use Test::More 'no_plan';

use LWP::UserAgent;
use LWP::ConnCache;
use HTTP::Request;
use HTTP::Request::Common;
use POE;
use POE::Component::Server::SimpleHTTP;
use POE::Component::WebApp;
use POE::Component::WebApp::Adapter::SimpleHTTP;

my $PORT = 2080;
my $IP = "localhost";

my $pid = fork;
die "Unable to fork: $!" unless defined $pid;

END {
    if ($pid) {
        kill 2, $pid or warn "Unable to kill $pid: $!";
    }
}

####################################################################
if ($pid)  # we are parent
{                      
    # stop kernel from griping
    ${$poe_kernel->[POE::Kernel::KR_RUN]} |=
      POE::Kernel::KR_RUN_CALLED;

    diag("$$: Sleep 2...");
    sleep 2;
    diag("continue");
    diag('Get param check.');
    my $UA = LWP::UserAgent->new;
    my $req = GET "http://$IP:$PORT/dngortest/dngorish/paramparse?key1=value1";
    my $resp = $UA->request($req);
    ok( $resp->is_success, 'Successful request.');
    is( $resp->content, 
        'key: key1, value: value1.', 
        'Got the right content.' );
        
    diag('Hybrid check, post with get in the URI.');
    $req = POST "http://$IP:$PORT/dngortest/dngorish/paramparse?key2=value2";
    $resp = $UA->request($req);
    ok( $resp->is_success, 'Successful request.');
    is( $resp->content, 
        'key: key2, value: value2.', 
        'Got the right content.' );
        
    diag('POST param check.');
    $req = POST "http://$IP:$PORT/dngortest/dngorish/paramparse", [ key3 => 'value3' ];
    $resp = $UA->request($req);
    ok( $resp->is_success, 'Successful request.');
    is( $resp->content, 
        'key: key3, value: value3.', 
        'Got the right content.' );
    diag('POST param array check.');
    $req = POST "http://$IP:$PORT/dngortest/dngorish/paramparse", [ key => 'value',
                                                                    key3 => 'value3', 
                                                                    key3 => 'value4', 
                                                                    key3 => 'value5' ];
    $resp = $UA->request($req);
    ok( $resp->is_success, 'Successful request.');
    ok($resp->content =~ "key: key, value: value", "Found key: key and value: value, in response.");
    for (qw/3 4 5/)
    {
        ok($resp->content =~ "key: key3, value: value$_.", "Found key: key3 and value: $_, in response so arrays are working.");
    }
    $req = HTTP::Request->new(GET => "http://$IP:$PORT/dngorish/asyncfork");
    $resp = $UA->request($req);
    ok( $resp->is_success, 'Successful request.');
    is( $resp->content, 
        'This should come last.  spin spin1 spin2', 
        'Got the right content.' );
    
    $req = HTTP::Request->new(GET => "http://$IP:$PORT/asyncforward");
    $resp = $UA->request($req);
    ok( $resp->is_success, 'Successful request.');
    is( $resp->content, 
        'This is coming from spin.  This is coming from spin 1.  This is coming from spin 2.  This should come last.', 
        'Got the right content.' );
    
    $req = HTTP::Request->new(GET => "http://$IP:$PORT/dngorish/hotness");
    $resp = $UA->request($req);
    ok( $resp->is_success, 'Successful request.');
    is($resp->content, 'It is hot in here.', 'Got the right content.' );
    
    $req = HTTP::Request->new(GET => "http://$IP:$PORT/dngorish");
    $resp = $UA->request($req);
    ok( $resp->is_success, 'Successful request.');
    is( $resp->content, 'this is index of DngorTest::Dngorish', 'Got the right content.' );
    
    $req = HTTP::Request->new(GET => "http://$IP:$PORT/dngorish/hello");
    $resp = $UA->request($req);
    ok( $resp->is_success, 'Successful request.');
    is($resp->content, 'Hello there.', 'Got the right content.');
    
    $req = HTTP::Request->new(GET => "http://$IP:$PORT/");
    $resp = $UA->request($req);
    ok( $resp->is_success, 'Successful request.');
    is( $resp->content, 'this is index of DngorTest', 'Got the right content.' );
    
    $req = HTTP::Request->new(GET => "http://$IP:$PORT/");
    $resp = $UA->request($req);
    ok( $resp->is_success, 'Successful request.');
    is( $resp->content, 'this is index of DngorTest', 'Got the right content.' );
    
    $req = HTTP::Request->new(GET => "http://$IP:$PORT/arg1/arg2");
    $resp = $UA->request($req);
    ok( $resp->is_success, 'Successful request.');
    is( $resp->content, 'this is index of DngorTest arg1 arg2', 'Got the right content.' );
    
    $req = HTTP::Request->new(GET => "http://$IP:$PORT/dngorish/testargforward");
    $resp = $UA->request($req);
    ok( $resp->is_success, 'Successful request.');
    is( $resp->content, 'this is index of DngorTest arg3 arg4', 'Got the right content, for testforward.' );
    
    $req = HTTP::Request->new(GET => "http://$IP:$PORT/something");
    $resp = $UA->request($req);
    ok( $resp->is_success, 'Successful request.');
    is( $resp->content, 'This is coming from something, result was 6.', 'Got the right content.' );
    
    $req = HTTP::Request->new(GET => "http://$IP:$PORT/asyncforward");
    $resp = $UA->request($req);
    ok( $resp->is_success, 'Successful request.');
    is( $resp->content, 
        'This is coming from spin.  This is coming from spin 1.  This is coming from spin 2.  This should come last.', 
        'Got the right content.' );
    
    $req = HTTP::Request->new(GET => "http://$IP:$PORT/testforward");
    $resp = $UA->request($req);
    ok( $resp->is_success, 'Successful request.');
    is( $resp->content, 
        'This is coming from spin.  This is coming from spin 1.  This is coming from spin 2.', 
        'Got the right content.' );
        
    diag('Arg check.');
    $req = HTTP::Request->new(GET => "http://$IP:$PORT/echo/1/2/3");
    $resp = $UA->request($req);
    ok( $resp->is_success, 'Successful request.');
    is( $resp->content, 'Arg 1 Arg 2 Arg 3', 'Got the right content.');
}
####################################################################
else  # we are the child
{                          
    
    my $adapter =  POE::Component::WebApp::Adapter::SimpleHTTP->new( simple_alias => 'HTTPD' );
    
    my $app1 = POE::Component::WebApp->new( adapter => $adapter,
                                            handler_dir => 't/Handlers',
                                            root_namespace  => 'DngorTest',
                                          );
    
    POE::Component::Server::SimpleHTTP->new(
                'ALIAS'         =>      'HTTPD',
                'ADDRESS'       =>      "$IP",
                'PORT'          =>      $PORT,
                'HOSTNAME'      =>      'pocosimpletest.com',
                'HANDLERS'      =>      [
                        {
                                'DIR'           =>      '.*',
                                'EVENT'         =>      'DISPATCH',
                                'SESSION'       =>      $app1->session_id(),
                        },
                ],
    );
    
    $poe_kernel->run;
}



