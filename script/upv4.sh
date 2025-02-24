#!/bin/bash

# 定义新的端口范围
PORTS="22,53,80:100,443,2096,2520,5555,5580:5600,5690,8080,8000:8100"

# 删除现有的规则（如果需要）
sudo iptables -D INPUT -p tcp -m multiport --dports 22,53,80,81,443,2096,2520,5555,5580:5600,5690,8080,8000:8100 -j ACCEPT
sudo iptables -D INPUT -p udp -m multiport --dports 22,53,80,81,443,2096,2520,5555,5580:5600,5690,8080,8000:8100 -j ACCEPT

# 添加新的 TCP 规则
sudo iptables -A INPUT -p tcp -m multiport --dports $PORTS -j ACCEPT

# 添加新的 UDP 规则
sudo iptables -A INPUT -p udp -m multiport --dports $PORTS -j ACCEPT

# 显示更新后的 iptables 规则
sudo iptables -L -n
