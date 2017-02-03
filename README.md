# Twitter-Common-Followers

Go to: https://apps.twitter.com to register an application (to create an API Keys & Secret)

Edit twitter.pl and manually write in your API Keys and Secrets. I'll add command line support eventually? (maybe? I think it's just simpler to have it coded in rather than retype it everytime you run the script...)

# Features

- Lists all a persons followers in 'followers.txt' 1 follower username per line
- Automatically gets an OAuth Token for you
- Can use multiple API Keys and Secrets to avoid the API cap
  - Currently you're alloted a maximum of 30 requests every 15 minutes
  - Each request can contain a maximum of 200 followers
  - So we can only list 6,000 followers every 15 minutes with 1 API Key and Secret
 
# Planned

- Lists common/shared followers of two people
