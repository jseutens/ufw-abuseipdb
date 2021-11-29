#!/bin/bash
[ "$1" != "-q" ]
QUIET=$?
((QUIET)) || date
# https://www.howtoforge.com/tutorial/protect-your-server-computer-with-badips-and-fail2ban/
# based on this version http://www.timokorthals.de/?p=334
_ipt=/sbin/iptables    # Location of iptables (might be correct)
_iptv6=/sbin/ip6tables    # Location of iptables (might be correct)
# get your api key from https://www.abuseipdb.com/account/plans (the free plan lets you download the blacklist 10 times a day)
YOUR_API_KEY="xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
# check if chain exists
CHAIN_NAME="blacklist-abuseipdb"
CHAIN_NAMEv6="blacklist-abuseipdbv6"
CHAIN_NAME_FILE="/tmp/abuseipdb.txt";
# if iptables version >=1.4.x, you may use -S flag, not -L
#v6
if $_iptv6 -S $CHAIN_NAMEv6 > /dev/null
then
  #echo chain $CHAIN_NAME exists
  # flush the chain to repopulate with new downloaded ip list
  $_iptv6 -F $CHAIN_NAMEv6
else
  # echo chain $CHAIN_NAME not exists
  # create the chain with iptables
  $_iptv6 -N $CHAIN_NAME
fi
#v4
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
if ((QUIET==0)); then
  SILENT="-s"
else
  SILENT=""
fi
curl $SILENT -G https://api.abuseipdb.com/api/v2/blacklist -d countMinimum=15 -d maxAgeInDays=60 -d confidenceMinimum=85 -H "Key:$YOUR_API_KEY" -H "Accept: text/plain" > $CHAIN_NAME_FILE
#
# list for adding the IPV4 ips
COMBINEDIPV4="/tmp/abuseipdbipv4.txt"
# list for adding the IPV6 ips
COMBINEDIPV6="/tmp/abuseipdbipv6.txt"
#
# split the list in a ipv4 list and a ipv6 list
# check for ip4 or ip6
grep '^\([0-9]\{1,3\}\.\)\{3\}[0-9]\{1,3\}$' $CHAIN_NAME_FILE > $COMBINEDIPV4
grep '^[0-9a-f:]+$' $CHAIN_NAME_FILE > $COMBINEDIPV6
# first v6 , v4 will be added later before v6 , so v4 has better possibility to match so no v6 rules will be used as its match a blocking , less memory use
#insert ipv6 IP
COUNTER=0
for IPv6 in $( cat $COMBINEDIPV6 ); do
 # if you want the logging enable following line
 # $_iptv6 -A $CHAIN_NAMEv6 -s $IPv6 -j LOG --log-prefix "ABUSEDBIP"
  $_iptv6 -A $CHAIN_NAMEv6 -s $IPv6 -j DROP
  ((QUIET)) || echo -n .
    if [ $COUNTER -eq 50 ]
    then
      ((QUIET)) || echo
      COUNTER=0
    fi
  ((COUNTER++))
done
#
# Finally, insert or append our black list v6
$_iptv6 -I INPUT -j $CHAIN_NAMEv6
$_iptv6 -I OUTPUT -j $CHAIN_NAMEv6
$_iptv6 -I FORWARD -j $CHAIN_NAMEv6
#
#
#insert ipv4 IP
COUNTER=0
for IP in $( cat $COMBINEDIPV4 ); do
 # if you want the logging enable following line
 # $_ipt -A $CHAIN_NAME -s $IP -j LOG --log-prefix "ABUSEDBIP"
  $_ipt -A $CHAIN_NAME -s $IP -j DROP
  ((QUIET)) || echo -n .
    if [ $COUNTER -eq 50 ]
    then
      ((QUIET)) || echo
      COUNTER=0
    fi
  ((COUNTER++))
done
#
# Finally, insert or append our black list
$_ipt -I INPUT -j $CHAIN_NAME
$_ipt -I OUTPUT -j $CHAIN_NAME
$_ipt -I FORWARD -j $CHAIN_NAME
#
rm $COMBINEDIPV4 $COMBINEDIPV6
rm $CHAIN_NAME_FILE
((QUIET)) || date
