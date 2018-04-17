#!/usr/bin/perl

use JSON;
use File::Slurp;
use MIME::Base64;
use vars qw();

my $followersToList = "artosis";

# merry go round
our @applicationNames = ("AppName1", "AppName2", "AppName3");
our @keys = ("KeyHere1", "KeyHere2", "KeyHere3");
our @secrets = ("SecretHere1", "SecretHere2", "SecretHere3");

our $startTime = time;
our $startTimeo = time;

# first run of the script will use the first key/secret/appname [0] from above
my $keyNumber = 0; #index of which key to use

my $applicationName = @applicationNames[$keyNumber];
my $key = @keys[$keyNumber];
my $secret = @secrets[$keyNumber];
my $token = newToken($key, $secret, $applicationName); 

# gets the first chunk (max 200) followers
my @userListing = freshFetch($token, $applicationName, $followersToList);

if (@userListing[1] =~ /^0$/) {
	print "Process has complete. Follower list in 'followers.txt'\n";
	write_file("followers.txt", @userListing[0]);
}
elsif (@userListing[1] > 0) {
	write_file("followers.txt", @userListing[0]);
	print "Looks like we've successfully fetched the first 200 followers.\n";
	print "There is more we can get!\n";
	print "Type 'y' to continue fetching followers or\n";
	print "Type 'n' to stop\n";
	print "(y/n): ";
	chomp(my $answer = <STDIN>);
	print "This'll take awhile...\n";
	if ($answer =~ /^y|Y$/) {
		$startTime = time;
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
	if (defined @parms[3]) {
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
	if (!defined @parms[3]) {
		$cursor = "1399215995467571167";
	}
	else {
		$cursor = @parms[3];
	}
	my $res = `curl -s -A "@parms[1]" --header "Authorization: Bearer @parms[0]" "https://api.twitter.com/1.1/followers/list.json?count=200&screen_name=@parms[2]&cursor=$cursor"`;
	my $decodedJson = decode_json($res);
	my $followers = $decodedJson->{'users'};
	$list = "";
	for ($i = 0; $i < scalar(@{$followers}); $i++) {
		$list .= $decodedJson->{'users'}[$i]{'screen_name'}."\n";
	}
	my @listing = ($list, $decodedJson->{'next_cursor'}, $res);
	return @listing;
}

our $temporaryStorage;
sub recursiveCaller {
	my @parms = @_;
	my @res = freshFetch(@parms[0], @parms[1], @parms[2], @parms[3]);
	if (@res[1] > 0) {
		append_file("followers.txt", @res[0]);
		$temporaryStorage = @res[1];
		recursiveCaller(@parms[0], @parms[1], @parms[2], @res[1]);
	}
	else {
		append_file("followers.txt", @res[0]);

		if (@res[1] =~ /^0$/) {
			$duration = time - $startTimeo;
			die "Looks like we've reached the end!\nCeasing use of App: " . @parms[1] . "\nDURATION: " . $duration . " seconds\n";
		}
		else {
			## possible that we ran out of qouta, or??
			if ((decode_json(@res[2])->{"errors"}[0]{"code"}) =~ /^88$/) {
				print "Exceeded qouta, attempting to continue...[cursor: $temporaryStorage]\n";
				goto CONTINUEAPP;
			}
			elsif ((decode_json(@res[2])->{"errors"}[0]{"code"}) =~ /^130$/) {
				print "Over capacity error, attempting to skip this key...[cursor: $temporaryStorage]\n";
				goto CONTINUEAPP;
			}
			else {
				die  @res[2] . "[cursor: $temporaryStorage]\n";
			}
		}
		CONTINUEAPP:
		$d = 0;
		$j = 0;
		for ($j; $j < scalar(@applicationNames); $j++) {
			if (@applicationNames[$j] =~ /^@parms[1]$/) {
				$found = $j
			}
		}

		if (scalar(@applicationNames) > $found+1) {
			print "Looks like we can proceed with another API key (index: ".($found+1).")\n";
			recursiveCaller(newToken(0, 0, @applicationNames[$found+1], $found+1), @applicationNames[$found+1], @parms[2], $temporaryStorage);
		}
		else {
			my $sleepTime = ( 900 - (time - $startTime) );
			print "Used all ". ($found+1) ." API keys available.\nWill sleep(seconds: $sleepTime) until 15 minutes from execution has passed.\n";
			sleep($sleepTime);
			$startTime = time;
			print "Restarting process\nWARNING: You'll need to manually kill script beyond now, may loop forawhile in unable to use API key b/c threshold\n\n";
			recursiveCaller(newToken(0, 0, @applicationNames[0], 0), @applicationNames[0], @parms[2], $temporaryStorage);
		}
	}
}