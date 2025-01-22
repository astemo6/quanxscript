#!/bin/bash

# 确保 SSH（端口 2520）始终允许
echo "Allowing SSH (port 2520) to prevent disconnection..."
sudo iptables -A INPUT -p tcp --dport 2520 -j ACCEPT
sudo iptables -A INPUT -p udp --dport 2520 -j ACCEPT

# 清除现有的 iptables 规则
echo "Flushing iptables rules..."
sudo iptables -F
sudo iptables -t filter -F

# 设置默认策略为 DROP（拒绝所有流量）
echo "Setting default iptables policies to DROP (Input) and ACCEPT (Forward/Output)..."
sudo iptables -P INPUT DROP
sudo iptables -P FORWARD ACCEPT
sudo iptables -P OUTPUT ACCEPT

# 允许已建立连接和相关数据包通过
echo "Allowing established and related connections..."
sudo iptables -A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT

# 允许回环接口流量
echo "Allowing loopback interface..."
sudo iptables -A INPUT -i lo -j ACCEPT

# 允许 ICMP 流量
echo "Allowing ICMP (ping)..."
sudo iptables -A INPUT -p icmp -j ACCEPT

# 允许 UDP 协议、源端口为 123 的流量
echo "Allowing UDP port 123 (NTP)..."
sudo iptables -A INPUT -p udp --sport 123 -j ACCEPT

# 允许多个端口的 TCP 和对应的 UDP 流量
echo "Allowing multiple ports for both TCP and UDP..."
PORTS="22,53,80,81,443,2096,2520,5555,5580:5600,5690,8080,8000:8100"

# 添加 TCP 规则
sudo iptables -A INPUT -p tcp -m multiport --dports $PORTS -j ACCEPT

# 添加对应的 UDP 规则
sudo iptables -A INPUT -p udp -m multiport --dports $PORTS -j ACCEPT

# 允许所有出口流量
echo "Allowing all outbound traffic..."
sudo iptables -A OUTPUT -j ACCEPT

# 允许所有转发流量
echo "Allowing all forwarded traffic..."
sudo iptables -A FORWARD -j ACCEPT

# 拒绝所有未匹配规则的流量，并发送 ICMP 主机不可达错误消息
echo "Rejecting unmatched packets..."
sudo iptables -A INPUT -j REJECT --reject-with icmp-host-prohibited

# 保存规则到文件
echo "Saving iptables rules..."
sudo sh -c 'iptables-save > /etc/iptables/rules.v4'

# 确保规则文件加载成功
echo "Restoring iptables rules..."
sudo iptables-restore < /etc/iptables/rules.v4

# 启用 iptables 服务
echo "Enabling iptables service..."
sudo systemctl enable iptables

# 检查规则是否生效
echo "Checking current iptables rules..."
sudo iptables -L INPUT --line-numbers
