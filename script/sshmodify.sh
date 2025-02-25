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

# 确保 /etc/ssh/sshd_config.d/60-cloudimg-settings.conf 允许密码登录
echo "Ensuring password authentication in /etc/ssh/sshd_config.d/60-cloudimg-settings.conf..."
sudo sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication yes/g' /etc/ssh/sshd_config.d/60-cloudimg-settings.conf

# 设置 SSH 端口为 2520
echo "Changing SSH port to 2520..."
sudo sed -i 's/^#\?Port .*/Port 2520/g' /etc/ssh/sshd_config

# 重启 SSH 服务
echo "Restarting SSH service..."
sudo systemctl restart sshd

# 检测 fail2ban 是否安装
if ! command -v fail2ban-client &> /dev/null; then
    echo "Fail2ban 未安装，正在安装..."
    sudo apt update && sudo apt install -y fail2ban
else
    echo "Fail2ban 已安装，跳过安装步骤。"
fi

# 配置 fail2ban 规则（20 分钟内失败 10 次，永久封禁）
config_file="/etc/fail2ban/jail.local"
echo "Updating fail2ban configuration..."
sudo bash -c "cat > $config_file <<EOF
[sshd]
enabled = true
port    = 2520
filter  = sshd
logpath = /var/log/auth.log
bantime = -1
findtime = 20m
maxretry = 10
EOF"

# 启动 fail2ban
echo "Restarting fail2ban service..."
sudo systemctl restart fail2ban

# 显示 fail2ban 运行状态
echo "Fail2ban 运行状态："
sudo systemctl status fail2ban --no-pager

echo "所有设置完成："
echo "1. SSH 端口已修改为 2520。"
echo "2. 已允许 root 密码登录。"
echo "3. Fail2ban 已安装并配置，20 分钟内失败 10 次将被永久封禁！"
