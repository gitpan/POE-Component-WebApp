package POE::Component::WebApp::Util::Attr;
use strict;
use warnings;
use Exporter qw(import);
use vars qw(@EXPORT_OK);

@EXPORT_OK = (qw/get_attribs has_attrib split_attr fork_this/);

sub get_attribs
{
    no warnings 'once';
    my $code_ref = shift;
    return $POE::Component::WebApp::Controller::attrib_table{ $code_ref };
}

sub has_attrib
{
    my ($code_ref, $attrib) = @_;
    my $attrs = get_attribs( $code_ref );
    for (@$attrs)
    {
        my ($type, $args) = split_attr($_);
        return ($type, $args)
            if $type eq $attrib;
    }
    return undef;
}

sub split_attr
{
    my $full_attr = shift;
    
    my ($type, $args) = $full_attr =~ /\(/ ? $full_attr =~ m/^(.*)\((.*)\)/
                                           : $full_attr;
    $args =~ s/'//g
        if defined $args;
    return ($type, $args);
}

use Data::Dumper;

sub fork_this
{
    my $code_ref = shift;
    my @info = has_attrib( $code_ref, 'Async');
    
    return 0
        unless defined $info[1];
        
    for (split(/,/,$info[1]))
    {
        return 1
            if lc($_) eq 'fork';
    }
    
    return 0;
}

1;