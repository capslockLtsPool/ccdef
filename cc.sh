#!/bin/sh

IPTABLES="/sbin/iptables"
echo "1" > /proc/sys/net/ipv4/ip_forward
$IPTABLES -P INPUT DROP
$IPTABLES -P FORWARD DROP
$IPTABLES -P OUTPUT DROP
$IPTABLES -F
$IPTABLES -X
$IPTABLES -Z
#$IPTABLES -A INPUT -m state �Cstate ESTABLISHED,RELATED -j ACCEPT
# ���ͬʱ��80�˿ڵ�����������10����Drop�����ip
netstat -an | grep :80 | awk -F: '{ print $8 }' | sort | uniq -c | awk -F\ '$1>10 && $2!="" { print $2 }' >> /etc/fw.list
less /etc/fw.list | sort | uniq -c | awk -F\ '$2!="" { print $2 }' > /etc/fw.list2
less /etc/fw.list2 > /etc/fw.list
while read line
do
t=`echo "$line"`
$IPTABLES -A INPUT -p tcp -s $t -j DROP
done < /etc/fw.list2
$IPTABLES -A INPUT -m state �Cstate ESTABLISHED,RELATED -j ACCEPT
$IPTABLES -A INPUT -p tcp �Cdport 22 -j ACCEPT
$IPTABLES -A INPUT -p tcp �Cdport 443 �Ctcp-flags SYN,ACK,FIN,RST SYN -m limit �Climit 30/m �Climit-burst 2 -j ACCEPT
$IPTABLES -A INPUT -p tcp �Cdport 80 �Ctcp-flags SYN,ACK,FIN,RST SYN -m limit �Climit 30/m �Climit-burst 2 -j ACCEPT
#��������������web���񣬵���IP�Ĳ������Ӳ�����10���������ı��ܾ�
$IPT -A INPUT -i $INTERNET -p tcp �Cdport 80 -m connlimit �Cconnlimit-above 10 -j REJECT
$IPT -A INPUT -i $INTERNET -p tcp �Cdport 443 -m connlimit �Cconnlimit-above 10 -j REJECT
#��������������web���񣬵���IP��60����ֻ��������½�15�����ӣ������ı��ܾ�
$IPT -A INPUT -i $INTERNET -p tcp �Cdport 80 -m recent �Cname BAD_HTTP_ACCESS �Cupdate �Cseconds 60 �Chitcount 15 -j REJECT
$IPT -A INPUT -i $INTERNET -p tcp �Cdport 80 -m recent �Cname BAD_HTTP_ACCESS �Cset -j ACCEPT
$IPT -A INPUT -i $INTERNET -p tcp �Cdport 443 -m recent �Cname BAD_HTTP_ACCESS �Cupdate �Cseconds 60 �Chitcount 15 -j REJECT
$IPT -A INPUT -i $INTERNET -p tcp �Cdport 443 -m recent �Cname BAD_HTTP_ACCESS �Cset -j ACCEPT
#��������������web����1��C�ε�IP�Ĳ������Ӳ�����150���������ı��ܾ�
$IPT -A INPUT -i $INTERNET -p tcp �Cdport 80 -m iplimit �Ciplimit-above 150 �Ciplimit-mask 24 -j REJECT
$IPT -A INPUT -i $INTERNET -p tcp �Cdport 443 -m iplimit �Ciplimit-above 150 �Ciplimit-mask 24 -j REJECT

$IPTABLES -A OUTPUT -p tcp -s 127.0.0.1 -j ACCEPT
$IPTABLES -A OUTPUT -p udp -s 127.0.0.1 -j ACCEPT

$IPTABLES -A INPUT -p tcp �Csyn -j DROP
#��ֹ��tracert
iptables -A INPUT -m ttl �Cttl-eq 1 -j DROP
iptables -A INPUT -m ttl �Cttl-lt 4 -j DROP
iptables -A FORWARD -m ttl �Cttl-lt 6 -j DROP