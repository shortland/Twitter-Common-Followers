#!/usr/bin/perl

use JSON;
use File::Slurp;
use MIME::Base64;

my $followersToList = "ilankleiman";
my $applicationName = "IlanKleimanApp";
my $key = "";
my $secret = "";

# pretty static, but 99% will be using multiple keys since twitter api is limiting
## 99% cus there is a chance that cursor is passable between applications :(
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

sub recursiveCaller {
	my @parms = @_;
	my @res = freshFetch(@parms[0], @parms[1], @parms[2], @parms[3]);
	if(@res[1] > 0) {
		append_file("followers.txt", @res[0]);
		recursiveCaller(@parms[0], @parms[1], @parms[2], @res[1]);
	}
	else {
		# looks like we need to do this one last time:
		append_file("followers.txt", @res[0]);

		my $exit = @res[1];
		if($exit =~ /^$/) {
			$exit = "max requests";
		}
		print "Looks like we've reached the end!\n" . $exit;
		#sleep(2);
		#append_file("followers.txt", "END: " . $exit);
	}
}


