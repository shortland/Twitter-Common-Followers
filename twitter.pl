#!/usr/bin/perl

use JSON;
use File::Slurp;
use MIME::Base64;

# GETS BEARER ACCESS TOKEN
#$req = `curl -v -A "IlanKleimanApp" --header "Content-Type: application/x-www-form-urlencoded;charset=UTF-8" --header "Authorization: Basic aaaa:aaaa" --data "oauth_consumer_key=unnecessart?&" -d "grant_type=client_credentials" "https://api.twitter.com/oauth2/token" -L`;
# > {"token_type":"bearer","access_token":"AaAAAAAAAAAAAAAAA"}

getPrint();
sub newToken {
	my $key = "key";
	my $secret = "sec";

	my $hashed = encode_base64($key . ":" . $secret);
	my $res = `curl -v -A "angulate" --header "Content-Type: application/x-www-form-urlencoded;charset=UTF-8" --header "Authorization: Basic $hashed" -d "grant_type=client_credentials" "https://api.twitter.com/oauth2/token" -L`;
	print $res;
}

sub getPrint {
	my @parms = @_;
	$token = "token";

	$res = `curl -s -A "IlanKleimanApp" --header "Authorization: Bearer $token" "https://api.twitter.com/1.1/followers/list.json?count=100&screen_name=artosis&cursor=-1" > followers.txt`;

	$json = read_file("followers.txt");
	$decodedJson = decode_json($json);

	if($decodedJson->{'next_cursor'} !~ /^0$/) {
		$res = `curl -s -A "IlanKleimanApp" --header "Authorization: Bearer $token" "https://api.twitter.com/1.1/followers/list.json?count=100&screen_name=artosis&cursor=-1" > followers.txt`;

		$json = read_file("followers.txt");
		$decodedJson = decode_json($json);
	}
	$c = 0;

	print "<".$decodedJson->{'next_cursor'}."<";
	while($decodedJson->{'next_cursor'} > 0) {
		$nCursor = $decodedJson->{'next_cursor'};
		$res = `curl -s -A "IlanKleimanApp" --header "Authorization: Bearer $token" "https://api.twitter.com/1.1/followers/list.json?count=100&screen_name=artosis&cursor=$nCursor" > followers_${c}.txt`;

		$json = read_file("followers_".$c.".txt");
		$decodedJson = decode_json($json);
		$ref = $decodedJson->{'users'};
		#print "\n".scalar(@{$ref})." followers\n\n";

		for($i = 0; $i < scalar(@{$ref}); $i++) {
			print $decodedJson->{'users'}[$i]{'screen_name'}."\n";
		}
		$c++;
		sleep(4);
	}
}