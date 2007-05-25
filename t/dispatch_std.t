#!/usr/bin/perl -w

use strict;
use warnings;
#use Test::More tests => 12;
use Test::More 'no_plan';

use LWP::UserAgent;
use LWP::ConnCache;
use HTTP::Request;
use POE;
use POE::Kernel;
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
    my $UA = LWP::UserAgent->new;
    my $req = HTTP::Request->new(GET => "http://$IP:$PORT/dngortest/dngorish/asyncfork");
    my $resp = $UA->request($req);
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
    
    $req = HTTP::Request->new(GET => "http://$IP:$PORT/dngortest/dngorish/hotness");
    $resp = $UA->request($req);
    ok( $resp->is_success, 'Successful request.');
    is($resp->content, 'It is hot in here.', 'Got the right content.' );
    
    $req = HTTP::Request->new(GET => "http://$IP:$PORT/dngortest/dngorish");
    $resp = $UA->request($req);
    ok( $resp->is_success, 'Successful request.');
    is( $resp->content, 'this is index of DngorTest::Dngorish', 'Got the right content.' );
    
    $req = HTTP::Request->new(GET => "http://$IP:$PORT/dngortest/dngorish/hello");
    $resp = $UA->request($req);
    ok( $resp->is_success, 'Successful request.');
    is($resp->content, 'Hello there.', 'Got the right content.');
    
    $req = HTTP::Request->new(GET => "http://$IP:$PORT/dngortest");
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
    
    $req = HTTP::Request->new(GET => "http://$IP:$PORT/dngortest/dngorish/testargforward");
    $resp = $UA->request($req);
    ok( $resp->is_success, 'Successful request.');
    is( $resp->content, 'this is index of DngorTest arg3 arg4', 'Got the right content, for testforward.' );
    
    $req = HTTP::Request->new(GET => "http://$IP:$PORT/something");
    $resp = $UA->request($req);
    ok( $resp->is_success, 'Successful request.');
    is( $resp->content, 'This is coming from something, result was 6.', 'Got the right content.' );
    
    #$req = HTTP::Request->new(GET => "http://$IP:$PORT/async_forward");
    #$resp = $UA->request($req);
    #ok( $resp->is_success, 'Successful request.');
    #is( $resp->content, 
        #'This is coming from spin.  This is coming from spin 1.  This is coming from spin 2.', 
        #'Got the right content.' );
    
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



