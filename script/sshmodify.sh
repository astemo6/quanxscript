#!/bin/bash

# 停止 fail2ban 服务
echo "Stopping fail2ban service..."
systemctl stop fail2ban

# 清除 fail2ban 数据库和日志
echo "Flushing fail2ban logs and database..."
sudo fail2ban-client flushlogs
sudo rm -f /var/lib/fail2ban/fail2ban.sqlite3
sudo truncate -s 0 /var/log/fail2ban.log

# 清除系统日志文件
echo "Clearing system logs..."
sudo truncate -s 0 /var/log/auth.log
sudo rm -rf /var/log/*.gz
sudo rm -rf /var/log/*.1
sudo rm -rf /var/log/*.0

# 开启 root 登录
echo "Enabling root login..."
sudo sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin yes/g' /etc/ssh/sshd_config

# 开启密码认证
echo "Enabling password authentication..."
sudo sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication yes/g' /etc/ssh/sshd_config

# 开启证书认证
echo "Enabling/Keeping public key authentication..."
sudo sed -i 's/^#\?PubkeyAuthentication.*/PubkeyAuthentication yes/g' /etc/ssh/sshd_config

# 编辑 /etc/ssh/sshd_config.d/60-cloudimg-settings.conf 文件，确保密码登录开启
echo "Ensuring password authentication in /etc/ssh/sshd_config.d/60-cloudimg-settings.conf..."
sudo sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication yes/g' /etc/ssh/sshd_config.d/60-cloudimg-settings.conf

# 设置 SSH 使用端口 2520
echo "Changing SSH port to 2520..."
sudo sed -i 's/^#\?Port .*/Port 2520/g' /etc/ssh/sshd_config

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

# 允许多个端口的流量，包括端口 2520
echo "Allowing multiple ports including 2520..."
sudo iptables -A INPUT -p tcp -m multiport --dports 22,53,80,443,2096,2520,5555,5580:5600,8080,8000:8100 -j ACCEPT

# 拒绝所有未匹配规则的流量，并发送 ICMP 主机不可达错误消息
echo "Rejecting unmatched packets..."
sudo iptables -A INPUT -j REJECT --reject-with icmp-host-prohibited

# 允许所有出口流量
echo "Allowing all outbound traffic..."
sudo iptables -A OUTPUT -j ACCEPT

# 允许所有转发流量
echo "Allowing all forwarded traffic..."
sudo iptables -A FORWARD -j ACCEPT

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
sudo iptables -L -v --line-numbers

# 重启 SSH 服务以使更改生效
echo "Restarting SSH service..."
sudo systemctl restart sshd

# 启动并检查 fail2ban 服务状态
echo "Starting fail2ban service..."
systemctl start fail2ban
echo "fail2ban 服务状态："
systemctl status fail2ban

# 完成设置
echo "所有设置完成："
echo "1. 新端口 2520 已生效。"
echo "2. 已允许 root 密码登录。"
echo "3. fail2ban 记录已清除并重新启动。"
