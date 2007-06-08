package POE::Component::WebApp::Dispatcher::Result::Deferred;
use strict;
use warnings;

use base qw/POE::Component::WebApp::Dispatcher::Result/;

__PACKAGE__->mk_accessors(qw/callbacks postbacks err_backs/);

1;