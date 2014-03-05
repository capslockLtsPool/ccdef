#!/bin/sh

IPTABLES="/sbin/iptables"
echo "1" > /proc/sys/net/ipv4/ip_forward
$IPTABLES -P INPUT DROP
$IPTABLES -P FORWARD DROP
$IPTABLES -P OUTPUT DROP
$IPTABLES -F
$IPTABLES -X
$IPTABLES -Z
#$IPTABLES -A INPUT -m state –state ESTABLISHED,RELATED -j ACCEPT
# 如果同时在80端口的连接数大于10，就Drop掉这个ip
netstat -an | grep :80 | awk -F: '{ print $8 }' | sort | uniq -c | awk -F\ '$1>10 && $2!="" { print $2 }' >> /etc/fw.list
less /etc/fw.list | sort | uniq -c | awk -F\ '$2!="" { print $2 }' > /etc/fw.list2
less /etc/fw.list2 > /etc/fw.list
while read line
do
t=`echo "$line"`
$IPTABLES -A INPUT -p tcp -s $t -j DROP
done < /etc/fw.list2
$IPTABLES -A INPUT -m state –state ESTABLISHED,RELATED -j ACCEPT
$IPTABLES -A INPUT -p tcp –dport 22 -j ACCEPT
$IPTABLES -A INPUT -p tcp –dport 443 –tcp-flags SYN,ACK,FIN,RST SYN -m limit –limit 30/m –limit-burst 2 -j ACCEPT
$IPTABLES -A INPUT -p tcp –dport 80 –tcp-flags SYN,ACK,FIN,RST SYN -m limit –limit 30/m –limit-burst 2 -j ACCEPT
#限制连往本机的web服务，单个IP的并发连接不超过10个，超过的被拒绝
$IPT -A INPUT -i $INTERNET -p tcp –dport 80 -m connlimit –connlimit-above 10 -j REJECT
$IPT -A INPUT -i $INTERNET -p tcp –dport 443 -m connlimit –connlimit-above 10 -j REJECT
#限制连往本机的web服务，单个IP在60秒内只允许最多新建15个连接，超过的被拒绝
$IPT -A INPUT -i $INTERNET -p tcp –dport 80 -m recent –name BAD_HTTP_ACCESS –update –seconds 60 –hitcount 15 -j REJECT
$IPT -A INPUT -i $INTERNET -p tcp –dport 80 -m recent –name BAD_HTTP_ACCESS –set -j ACCEPT
$IPT -A INPUT -i $INTERNET -p tcp –dport 443 -m recent –name BAD_HTTP_ACCESS –update –seconds 60 –hitcount 15 -j REJECT
$IPT -A INPUT -i $INTERNET -p tcp –dport 443 -m recent –name BAD_HTTP_ACCESS –set -j ACCEPT
#限制连往本机的web服务，1个C段的IP的并发连接不超过150个，超过的被拒绝
$IPT -A INPUT -i $INTERNET -p tcp –dport 80 -m iplimit –iplimit-above 150 –iplimit-mask 24 -j REJECT
$IPT -A INPUT -i $INTERNET -p tcp –dport 443 -m iplimit –iplimit-above 150 –iplimit-mask 24 -j REJECT

$IPTABLES -A OUTPUT -p tcp -s 127.0.0.1 -j ACCEPT
$IPTABLES -A OUTPUT -p udp -s 127.0.0.1 -j ACCEPT

$IPTABLES -A INPUT -p tcp –syn -j DROP
#防止被tracert
iptables -A INPUT -m ttl –ttl-eq 1 -j DROP
iptables -A INPUT -m ttl –ttl-lt 4 -j DROP
iptables -A FORWARD -m ttl –ttl-lt 6 -j DROP