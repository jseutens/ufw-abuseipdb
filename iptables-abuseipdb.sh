#!/bin/bash
# https://www.howtoforge.com/tutorial/protect-your-server-computer-with-badips-and-fail2ban/
# based on this version http://www.timokorthals.de/?p=334
_ipt=/sbin/iptables    # Location of iptables (might be correct)
_input=badips.db       # Name of database (will be downloaded with this name)
_pub_if=eth0           # Device which is connected to the internet (ex. $ifconfig for that)
_droplist=droplist     # Name of chain in iptables (Only change this if you have already a chain with this name)
# get your api key from https://www.abuseipdb.com/account/plans (the free plan lets you download the blacklist 10 times a day)
YOUR_API_KEY="xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
# check if chain exists
CHAIN_NAME="blacklist-abuseipdb"
CHAIN_NAME_FILE="/tmp/abuseipdb.txt";
# if iptables version >=1.4.x, you may use -S flag, not -L
if $_ipt -S $CHAIN_NAME > /dev/null
then
  #echo chain $CHAIN_NAME exists
  # flush the chain to repopulate with new downloaded ip list
  $_ipt -F $CHAIN_NAME
else
  # echo chain $CHAIN_NAME not exists
  # create the chain with iptables
  $_ipt -N $CHAIN_NAME
fi
#
# only do this once a day limit is 10 times for a free account per 24h 
curl -G https://api.abuseipdb.com/api/v2/blacklist -d countMinimum=15 -d maxAgeInDays=60 -d confidenceMinimum=75 -H "Key:$YOUR_API_KEY" -H "Accept: text/plain" > $CHAIN_NAME_FILE
#
# list for adding the IPV4 ips
COMBINEDIPV4="/tmp/abuseipdbipv4.txt"
# list for adding the IPV6 ips
COMBINEDIPV6="/tmp/abuseipdbipv6.txt"
#
# split the list in a ipv4 list and a ipv6 list
  for IP in $( cat $CHAIN_NAME_FILE); do
  # check for ip4 or ip6  (very unclean way , only check for colon , trust AbuseIPDB lists to have correct writing)
      if [[ $IP =~ .*:.* ]]
      then
        echo $IP >> $COMBINEDIPV6
       else
        echo $IP >> $COMBINEDIPV4
      fi
done
#
#insert ipv4 IP
for IP in $( cat $COMBINEDIPV4 ); do
  $_ipt -A $CHAIN_NAME -s $ip -j LOG --log-prefix "ABUSEDBIP"
  $_ipt -A $CHAIN_NAME -s $ip -j DROP
done
#
# Finally, insert or append our black list
$_ipt -I INPUT -j $CHAIN_NAME
$_ipt -I OUTPUT -j $CHAIN_NAME
$_ipt -I FORWARD -j $CHAIN_NAME
