#!/bin/bash

# **确保 SSH（端口 2520）始终允许**
echo "Allowing SSH (port 2520) to prevent disconnection..."
sudo ip6tables -A INPUT -p tcp --dport 2520 -j ACCEPT
sudo ip6tables -A INPUT -p udp --dport 2520 -j ACCEPT

# **清除现有的 ip6tables 规则**
echo "Flushing ip6tables rules..."
sudo ip6tables -F
sudo ip6tables -t filter -F

# **设置默认策略为 DROP（拒绝所有流量）**
echo "Setting default ip6tables policies to DROP (Input) and ACCEPT (Forward/Output)..."
sudo ip6tables -P INPUT DROP
sudo ip6tables -P FORWARD ACCEPT
sudo ip6tables -P OUTPUT ACCEPT

# **允许已建立连接和相关数据包通过**
echo "Allowing established and related connections..."
sudo ip6tables -A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT

# **允许回环接口流量**
echo "Allowing loopback interface..."
sudo ip6tables -A INPUT -i lo -j ACCEPT

# **允许 ICMPv6 流量**
echo "Allowing ICMPv6 (ping, neighbor discovery, etc)..."
sudo ip6tables -A INPUT -p ipv6-icmp -j ACCEPT

# **允许 DHCPv6 客户端获取 IPv6 地址**
echo "Allowing DHCPv6 client traffic..."
sudo ip6tables -A INPUT -p udp --dport 546 -j ACCEPT
sudo ip6tables -A INPUT -p udp --sport 547 -j ACCEPT

# **允许 NTP（端口123）时间同步流量**
echo "Allowing UDP port 123 (NTP)..."
sudo ip6tables -A INPUT -p udp --sport 123 -j ACCEPT

# **允许多个端口的 TCP 和对应的 UDP 流量**
echo "Allowing multiple ports for both TCP and UDP..."
PORTS="22,53,80:100,443,2096,2520,5555,5580:5600,5690,8080,8000:8100"
sudo ip6tables -A INPUT -p tcp -m multiport --dports $PORTS -j ACCEPT
sudo ip6tables -A INPUT -p udp -m multiport --dports $PORTS -j ACCEPT

# **允许所有出口流量**
echo "Allowing all outbound traffic..."
sudo ip6tables -A OUTPUT -j ACCEPT

# **允许所有转发流量**
echo "Allowing all forwarded traffic..."
sudo ip6tables -A FORWARD -j ACCEPT

# **拒绝所有未匹配规则的流量，并发送 ICMP 拒绝响应**
echo "Rejecting unmatched packets..."
sudo ip6tables -A INPUT -j REJECT --reject-with icmp6-adm-prohibited

# **保存规则到文件**
echo "Saving ip6tables rules..."
sudo mkdir -p /etc/iptables
sudo sh -c 'ip6tables-save > /etc/iptables/rules.v6'

# **恢复规则确保生效**
echo "Restoring ip6tables rules..."
sudo ip6tables-restore < /etc/iptables/rules.v6

# **启用 ip6tables 服务（如果系统支持）**
echo "Enabling ip6tables service..."
sudo systemctl enable ip6tables 2>/dev/null || echo "ip6tables service not found or not supported."

# **查看当前规则是否生效**
echo "Current ip6tables rules:"
sudo ip6tables -L INPUT --line-numbers -v
