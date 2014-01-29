#!/usr/bin/perl

use strict;
use warnings;
use Data::Dumper;

#for importing things to zabbix

sub main {
	my $command = Net::Zabbix::API->new({ url => 'http://your-server.com/zabbix' });
	my ( $zobject, $zmethod, $params) = ("host", "create", {some => "params"});

	my $res = $command->authenticate({ user => "SOME_USER", password => 'SOME_PASS' }); 
	
	#print Dumper($res);
	#$command->call( $zobject, $zmethod, $params );
}

__PACKAGE__->main();


package Net::Zabbix::API ;

use LWP::UserAgent;
use JSON::PP;
use Data::Dumper;

sub new {
	my $class = shift;
	my $params = shift;
	my $self = {};

	foreach my $param (keys %{$params}) {
		$self->{$param} = $params->{$param};
	}

	bless $self, $class;
	
	return $self;
}

sub call {
	my $self = shift;
	my ($zobject, $zmethod, $params) = (@_);
	
	$self->parse_params($params);
	$self->build_request();
	my $results = $self->request($zobject, $zmethod, $params);
	
	#print Dumper($self);
	return $results;
}

sub authenticate {
	my $self = shift;
	my ($credentials) = (@_);

	return $self->{auth_token} if $self->{auth_token};

	$self->parse_params($credentials); 

	my $res = $self->request("user", "login", 
			{ user => $self->{user}, password => $self->{password} });
	
	$self->{auth_token} = "";
	#delete $self->{password};
	return $self->{auth_token};
}

sub request {
	my $self = shift;
	my ($zobject, $zmethod, $params) = (@_);

	my $req = $self->build_request;

        $req->content($self->json_encode({
                jsonrpc => "2.0",
                method => "$zobject.$zmethod",
                params => $params,
                id => 1, #$self->next_id,
                auth => $self->{auth_token},
        }));

	my $res = $self->{ua}->request($self->{request});
	#delete $self->{request}->{_content}; #don't return json that contains password
	$res = $self->json_decode($res);
	print Dumper($res);

	return $res;
}

sub build_request {
        my $self = shift;

	$self->{ua} = LWP::UserAgent->new(agent => "Net::Zabbix::API", timeout => 3600 );

	$self->{request} = HTTP::Request->new(POST => "$self->{url}/api_jsonrpc.php");
	$self->{request}->content_type('application/json-rpc');

        return $self->{request};
}

sub json_encode {
	my $self = shift;
	my ($data) = (@_);

	my $json = JSON::PP->new
			->ascii
			->pretty
			->allow_nonref
			->allow_blessed
			->allow_bignum;

	return $json->encode($data);
}

sub json_decode {
	
}

sub parse_params {
	my ($self, $params) = (@_);
	
	foreach my $param (keys %{$params}) {
		$self->{$param} = $params->{$param};
	}
}
1;
