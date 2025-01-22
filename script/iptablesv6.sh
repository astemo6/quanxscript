#!/bin/bash

# **优先允许 SSH 服务的端口（例如 2250）以防断开连接**
SSH_PORT=2250
echo "Allowing SSH port $SSH_PORT to prevent disconnection..."
sudo ip6tables -A INPUT -p tcp --dport $SSH_PORT -j ACCEPT

# 清除现有的 ip6tables 规则
echo "Flushing existing ip6tables rules..."
sudo ip6tables -F
sudo ip6tables -t filter -F

# 设置默认策略为 DROP
echo "Setting default policies to DROP..."
sudo ip6tables -P INPUT DROP
sudo ip6tables -P FORWARD DROP
sudo ip6tables -P OUTPUT ACCEPT

# 允许回环接口流量
echo "Allowing loopback interface traffic..."
sudo ip6tables -A INPUT -i lo -j ACCEPT

# 允许已建立和相关的连接
echo "Allowing established and related connections..."
sudo ip6tables -A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT

# 允许 ICMPv6 流量（如 ping）
echo "Allowing ICMPv6 (ping)..."
sudo ip6tables -A INPUT -p ipv6-icmp -j ACCEPT

# 允许指定的 TCP 和 UDP 端口
PORTS="22,53,80,81,443,2096,2520,5555,5580:5600,5690,8080,8000:8100"
echo "Allowing specific TCP and UDP ports: $PORTS..."
sudo ip6tables -A INPUT -p tcp -m multiport --dports $PORTS -j ACCEPT
sudo ip6tables -A INPUT -p udp -m multiport --dports $PORTS -j ACCEPT

# 拒绝所有未匹配的流量
echo "Rejecting unmatched traffic..."
sudo ip6tables -A INPUT -j REJECT --reject-with icmp6-adm-prohibited

# 保存规则到文件
echo "Saving ip6tables rules to /etc/iptables/rules.v6..."
sudo mkdir -p /etc/iptables
sudo sh -c 'ip6tables-save > /etc/iptables/rules.v6'

# 确保规则文件加载成功
echo "Restoring ip6tables rules..."
sudo ip6tables-restore < /etc/iptables/rules.v6

# 启用 ip6tables 服务（如适用）
if systemctl list-units --type=service | grep -q 'ip6tables'; then
    echo "Enabling ip6tables service..."
    sudo systemctl enable ip6tables
fi

# 检查规则是否正确加载
echo "Current ip6tables rules:"
sudo ip6tables -L -v -n
