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
my $PORT2 = 2081;
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
    my $req = HTTP::Request->new(GET => "http://$IP:$PORT/dngortest/dngorish");
    my $resp = $UA->request($req);
    ok( $resp->is_success, 'Successful request.');
    is( $resp->content, 'this is index of DngorTest::Dngorish', 'Got the right content.' );
    
    $req = HTTP::Request->new(GET => "http://$IP:$PORT/dngortest2/dngorish");
    $resp = $UA->request($req);
    diag( $resp->content );
    is( $resp->code, 404, 'Good, dispatch table seperation.');
    
    $req = HTTP::Request->new(GET => "http://$IP:$PORT2/dngortest/dngorish");
    $resp = $UA->request($req);
    is( $resp->code, 404, 'Good, dispatch table seperation.');
    
    $req = HTTP::Request->new(GET => "http://$IP:$PORT/dngortest");
    $resp = $UA->request($req);
    ok( $resp->is_success, 'Successful request.');
    is( $resp->content, 'this is index of DngorTest', 'Got the right content.' );
    
    $req = HTTP::Request->new(GET => "http://$IP:$PORT2/dngortest2");
    $resp = $UA->request($req);
    ok( $resp->is_success, 'Successful request.');
    is( $resp->content, 'this is index of DngorTest2', 'Got the right content.' );
} 
####################################################################
else  # we are the child
{                          
    
### Two servers and two adapters 
### aren't needed for handling both apps. 
### but for this test it is necessary to check for dispatch table seperation
    my $adapter =  POE::Component::WebApp::Adapter::SimpleHTTP->new( simple_alias => 'HTTPD' );
    my $adapter2 =  POE::Component::WebApp::Adapter::SimpleHTTP->new( simple_alias => 'HTTPD2' );
    
    my $app1 = POE::Component::WebApp->new( adapter => $adapter,
                                            handler_dir => 't/Handlers',
                                           );
                                               
    my $app2 = POE::Component::WebApp->new( adapter => $adapter2,
                                            handler_dir => 't/Handlers2',
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
    
    POE::Component::Server::SimpleHTTP->new(
                'ALIAS'         =>      'HTTPD2',
                'ADDRESS'       =>      "$IP",
                'PORT'          =>      $PORT2,
                'HOSTNAME'      =>      'pocosimpletest2.com',
                'HANDLERS'      =>      [
                        {
                                'DIR'           =>      '.*',
                                'EVENT'         =>      'DISPATCH',
                                'SESSION'       =>      $app2->session_id(),
                        },
                ],
    );
    
    $poe_kernel->run;
}



