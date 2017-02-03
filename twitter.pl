#!/usr/bin/perl

use JSON;
use File::Slurp;
use MIME::Base64;
use vars qw(); # global variables... so we can access array of names/keys etc... really is me being lazy

my $followersToList = "artosis";

# merry go round
our @applicationNames = ("AppName1", "AppName2", "AppName3");
my $applicationName = @applicationNames[0];

our @keys = ("Key1ForApp1", "Key1ForApp2", "Key1ForApp3");
my $key = @keys[0];

our @secrets = ("Secret1ForApp1", "Secret1ForApp2", "Secret1ForApp3");
my $secret = @secrets[0];

my $token = newToken($key, $secret, $applicationName); 

# gets the first chunk (max 200) followers
my @userListing = freshFetch($token, $applicationName, $followersToList);

if(@userListing[1] =~ /^0$/) {
	print "Process has complete. Follower list in 'followers.txt'\n";
	write_file("followers.txt", @userListing[0]);
}
elsif(@userListing[1] > 0) {
	write_file("followers.txt", @userListing[0]);
	print "There is more we can get!\n";
	print "Type 'y' to continue fetching followers or\n";
	print "Type 'n' to stop\n";
	print "(y/n): ";
	chomp(my $answer = <STDIN>);
	print "This'll take awhile...\n";
	if($answer =~ /^y|Y$/) {
		recursiveCaller($token, $applicationName, $followersToList, @userListing[1]);
	}
	else {
		die "Process has complete. Follower list in 'followers.txt'\n";
	}
}
else {
	print "Couldn't find that persons followers, or possibly out of alloted API requests.\n";
	print "ERROR: " . @userListing[2] . "\n\n";
}


sub newToken {
	my @parms = @_;
	if(defined @parms[3]) {
		@parms[0] = @keys[@parms[3]];
		@parms[1] = @secrets[@parms[3]];
	}
	my $hashed = encode_base64(@parms[0] . ":" . @parms[1]);
	$hashed =~ s/\n//g;
	my $res = `curl -s -A "@parms[2]" --header "Content-Type: application/x-www-form-urlencoded;charset=UTF-8" --header "Authorization: Basic $hashed" --data "oauth_consumer_key=@parms[0]" -d "grant_type=client_credentials" "https://api.twitter.com/oauth2/token" -L`;
	$res = decode_json($res)->{'access_token'};
	return $res;
}

sub freshFetch {
	my @parms = @_;
	if(!defined @parms[3]) {
		$cursor = "-1";
	}
	else {
		$cursor = @parms[3];
	}
	my $res = `curl -s -A "@parms[1]" --header "Authorization: Bearer @parms[0]" "https://api.twitter.com/1.1/followers/list.json?count=200&screen_name=@parms[2]&cursor=$cursor"`;
	my $decodedJson = decode_json($res);
	my $followers = $decodedJson->{'users'};
	$list = "";
	for($i = 0; $i < scalar(@{$followers}); $i++) {
		$list .= $decodedJson->{'users'}[$i]{'screen_name'}."\n";
	}
	my @listing = ($list, $decodedJson->{'next_cursor'}, $res);
	return @listing;
}

our $temporaryStorage;
sub recursiveCaller {
	my @parms = @_;
	#token, appName, followersOf, cursor
	my @res = freshFetch(@parms[0], @parms[1], @parms[2], @parms[3]);
	if(@res[1] > 0) {
		append_file("followers.txt", @res[0]);
		$temporaryStorage = @res[1]; # temporarily store most recent valid cursor; so we can pass it to a working key if current key maxes out
		recursiveCaller(@parms[0], @parms[1], @parms[2], @res[1]);
	}
	else {
		append_file("followers.txt", @res[0]);

		my $exit = @res[1];
		if($exit =~ /^$/) {
			$exit = "Max requests reached!\n\n";
		}
		print "Looks like we've reached the end!\n" . $exit;
		## position of current app name (0)+1
		$j = 0;
		$found = -1;
		for($j; $j < scalar(@applicationNames); $j++) {
			if(@applicationNames[$j] =~ /^@parms[1]$/) {
				$found = $j
			}
		}

		if(scalar(@applicationNames) > $found+1) {
			print "Looks like we can proceed with another API key\n";
			recursiveCaller(newToken(0, 0, @applicationNames[$found+1], $found+1), @applicationNames[$found+1], @parms[2], $temporaryStorage);
		}
		else {
			print "Used all ". ($found+1) ." API keys available.\n";
			exit;
		}
	}
}


