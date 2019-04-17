#!/usr/bin/env bash
# based off the following script
# https://github.com/cowgill/spamhaus
# https://github.com/dajul/ufw-spamhaus
# https://joshtronic.com/2015/09/06/error-invalid-position-1/
# get your api key from https://www.abuseipdb.com/account/plans (the free plan lets you download the blacklist 10 times a day)
# I only use it once a day
$YOUR_API_KEY="xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
# save local copy here
FILE5="/tmp/abuseipdb.lasso";
# path to UFW
UFW="/usr/sbin/ufw";
# only do this once a day limit is 10 times for a free account per 24h 
curl -G https://api.abuseipdb.com/api/v2/blacklist -d countMinimum=15 -d maxAgeInDays=60 -d confidenceMinimum=85 -H "Key:$YOUR_API_KEY" -H "Accept: text/plain" > $FILE5
#
# all IPS , if exists remove these IP from UFW
COMBINEDIPALL=$FILE5
# list for adding the IPV4 ips
COMBINEDIPV4="/tmp/abusedropipv4.txt"
# list for adding the IPV6 ips
COMBINEDIPV6="/tmp/abusedropipv6.txt"
#
# remove all old entries out of UFW
#ipv6 and ipv4 can be in same list the delete command is the same for both
    if [ -f $COMBINEDIPALL ]; then
     for IP in $( cat $COMBINEDIPALL); do
      $UFW delete deny from $IP to any
     done
fi
#
# split the list in a ipv4 list and a ipv6 list
  for IP in $( cat $COMBINEDIPALL); do
  # check for ip4 or ip6  (very unclean way , only check for colon , trust AbuseIPDB lists to have correct writing)
      if [[ $IP =~ .*:.* ]]
      then
        echo $IP >> $COMBINEDIPV6
       else
        echo $IP >> $COMBINEDIPV4
      fi
done
#
# This is actually very slow so better is to create a new chain and insert it with iptables
#
#insert ipv4 IP
for IP in $( cat $COMBINEDIPV4 ); do
    $UFW insert 1 deny from $IP to any
done
#
#insert ipv6 IP
for IP in $( cat $COMBINEDIPV6); do
    v6ruleid=$(sudo ufw status numbered | grep "(v6)" | grep -o "\\[[0-9]*\\]" | grep -o "[0-9]*" | head -n 1)
    $UFW insert $v6ruleid deny from $IP to any
done
#
