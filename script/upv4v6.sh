#!/bin/bash

# 定义新的端口范围
PORTS="22,53,80:100,443,2096,2520,5555,5580:5600,5690,8080,8000:8100"

# 删除现有的 IPv4 TCP 和 UDP 规则（如果需要）
sudo iptables -D INPUT -p tcp -m multiport --dports 22,53,80,81,443,2096,2520,5555,5580:5600,5690,8080,8000:8100 -j ACCEPT
sudo iptables -D INPUT -p udp -m multiport --dports 22,53,80,81,443,2096,2520,5555,5580:5600,5690,8080,8000:8100 -j ACCEPT

# 删除现有的 IPv6 TCP 和 UDP 规则（如果需要）
sudo ip6tables -D INPUT -p tcp -m multiport --dports 22,53,80,81,443,2096,2520,5555,5580:5600,5690,8080,8000:8100 -j ACCEPT
sudo ip6tables -D INPUT -p udp -m multiport --dports 22,53,80,81,443,2096,2520,5555,5580:5600,5690,8080,8000:8100 -j ACCEPT

# 添加新的 IPv4 TCP 规则
sudo iptables -A INPUT -p tcp -m multiport --dports $PORTS -j ACCEPT

# 添加新的 IPv4 UDP 规则
sudo iptables -A INPUT -p udp -m multiport --dports $PORTS -j ACCEPT

# 添加新的 IPv6 TCP 规则
sudo ip6tables -A INPUT -p tcp -m multiport --dports $PORTS -j ACCEPT

# 添加新的 IPv6 UDP 规则
sudo ip6tables -A INPUT -p udp -m multiport --dports $PORTS -j ACCEPT

# 显示更新后的 IPv4 iptables 规则
echo "Updated IPv4 iptables rules:"
sudo iptables -L -n

# 显示更新后的 IPv6 ip6tables 规则
echo "Updated IPv6 ip6tables rules:"
sudo ip6tables -L -n

# **调整 REJECT 规则顺序**
echo "Adjusting REJECT rule position..."

# 删除 IPv4 REJECT 规则（如果存在）
sudo iptables -D INPUT -j REJECT --reject-with icmp-host-prohibited 2>/dev/null
# 重新添加 IPv4 REJECT 规则，确保它在最后
sudo iptables -A INPUT -j REJECT --reject-with icmp-host-prohibited

# 删除 IPv6 REJECT 规则（如果存在）
sudo ip6tables -D INPUT -j REJECT --reject-with icmp6-adm-prohibited 2>/dev/null
# 重新添加 IPv6 REJECT 规则，确保它在最后
sudo ip6tables -A INPUT -j REJECT --reject-with icmp6-adm-prohibited

# **显示最终规则**
echo "Updated IPv4 iptables rules:"
sudo iptables -L INPUT --line-numbers

echo "Updated IPv6 ip6tables rules:"
sudo ip6tables -L INPUT --line-numbers
