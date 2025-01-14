#!/bin/bash

# 开启 root 登录
echo "Enabling root login..."
sudo sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin yes/g' /etc/ssh/sshd_config

# 开启密码认证
echo "Enabling password authentication..."
sudo sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication yes/g' /etc/ssh/sshd_config

# 禁用键盘交互式认证
echo "Disabling KbdInteractiveAuthentication..."
sudo sed -i 's/^#\?KbdInteractiveAuthentication.*/KbdInteractiveAuthentication no/g' /etc/ssh/sshd_config

# 开启证书认证
echo "Enabling/Keeping public key authentication..."
sudo sed -i 's/^#\?PubkeyAuthentication.*/PubkeyAuthentication yes/g' /etc/ssh/sshd_config

# 编辑 /etc/ssh/sshd_config.d/60-cloudimg-settings.conf 文件，确保密码登录开启
echo "Ensuring password authentication in /etc/ssh/sshd_config.d/60-cloudimg-settings.conf..."
sudo sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication yes/g' /etc/ssh/sshd_config.d/60-cloudimg-settings.conf

# 设置 SSH 使用端口 2520
echo "Changing SSH port to 2520..."
sudo sed -i 's/^#\?Port .*/Port 2520/g' /etc/ssh/sshd_config

# 重启 SSH 服务以使更改生效
echo "Restarting SSH service..."
sudo systemctl restart sshd

# 停止 fail2ban 服务
echo "Stopping fail2ban service..."
sudo systemctl stop fail2ban

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

# 启动并检查 fail2ban 服务状态
echo "Starting fail2ban service..."
sudo systemctl start fail2ban
echo "fail2ban 服务状态："
sudo systemctl status fail2ban

# 完成设置
echo "所有设置完成："
echo "1. 新端口 2520 已生效。"
echo "2. 已允许 root 密码登录。"
echo "3. fail2ban 记录已清除并重新启动。"
