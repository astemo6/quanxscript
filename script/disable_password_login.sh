#!/bin/bash

# 设置 root 密码（可选）
# echo root:$ROOT_PASSWD | sudo chpasswd

# 禁用 root 登录
sudo sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin no/g' /etc/ssh/sshd_config

# 禁用密码认证
sudo sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication no/g' /etc/ssh/sshd_config

# 禁用键盘交互式认证
sudo sed -i 's/^#\?KbdInteractiveAuthentication.*/KbdInteractiveAuthentication no/g' /etc/ssh/sshd_config

# 启用证书认证
sudo sed -i 's/^#\?PubkeyAuthentication.*/PubkeyAuthentication yes/g' /etc/ssh/sshd_config

# 编辑 /etc/ssh/sshd_config.d/60-cloudimg-settings.conf 文件，禁用密码登录
sudo sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication no/g' /etc/ssh/sshd_config.d/60-cloudimg-settings.conf

# 重启 SSH 服务以使更改生效
sudo systemctl restart sshd

# 清除指定日志文件
sudo truncate -s 0 /var/log/auth.log

# 安装 Fail2Ban
sudo apt update
if ! sudo apt install -y fail2ban; then
    echo "Fail2Ban 安装失败！" >&2
    exit 1
fi

# 配置 Fail2Ban
cat <<EOF | sudo tee /etc/fail2ban/jail.local
[DEFAULT]
bantime = -1
findtime = 10m
maxretry = 5
backend = systemd
dbfile = /var/lib/fail2ban/fail2ban.sqlite3

[sshd]
enabled = true
port = ssh
logpath = /var/log/auth.log
EOF

# 重启并启用 Fail2Ban 服务
sudo systemctl restart fail2ban
sudo systemctl enable fail2ban

# 验证服务状态
sudo systemctl status fail2ban
sudo fail2ban-client status sshd
