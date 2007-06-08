#!/usr/bin/perl
# Load the Module::Install bundled in ./inc/
use inc::Module::Install;

# Define metadata
name 'POE-Component-WebApp';
author 'Marlon Bailey <mbailey at cpan.org>';
license 'perl';
all_from  'lib/POE/Component/WebApp.pm';

# Specific dependencies
requires        'POE'                   => '0.9989';
requires        'attributes'            => '0';
requires        'URI'                   => '0';
requires        'File::Find'            => '0';
requires        'Class::Inspector'      => '1.16';
requires        'HTTP::Status'          => '0';
requires        'HTTP::Request'         => '0';
requires        'HTTP::Request::Params' => '0';
requires        'Class::Accessor::Fast' => '0';
requires        'Scalar::Util' => '0';
requires        'Devel::Caller' => '0.11';
requires        'Devel::InnerPackage' => '0.3';
requires        'Text::TabularDisplay' => '1.22';
requires        'POE::Wheel::Run' => '1.2179';
requires        'Module::Info::File' => '0.11';
requires        'Module::Pluggable::Dependency' => '0.0.3';
requires        'POE::Filter::Reference' => '1.2025';

build_requires  'Test::More'        => '0.64';
build_requires  'POE::Component::Server::SimpleHTTP' => '1.23';
build_requires  'HTTP::Request::Common' => '0';

auto_install;
WriteAll;