#!/bin/bash

# 设置 root 密码（可选）
# echo root:YourRootPasswd | sudo chpasswd

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
sudo service sshd restart

# 清除日志文件
sudo truncate -s 0 /var/log/auth.log
sudo rm -rf /var/log/*.gz
sudo rm -rf /var/log/*.1
sudo rm -rf /var/log/*.0

# 安装 Fail2Ban
sudo apt update
sudo apt install -y fail2ban

# 配置 Fail2Ban
cat <<EOF | sudo tee /etc/fail2ban/jail.local

[DEFAULT]
bantime = -1           # 封禁时间，-1 表示永久封禁，可根据需要调整为 1h（1小时）或其他值
findtime = 10m         # 检测失败次数的时间窗口（如10分钟内）
maxretry = 5           # 最大失败尝试次数，建议设置为 5（默认是 10）
backend = systemd      # 使用 systemd 作为日志后端
dbfile = /var/lib/fail2ban/fail2ban.sqlite3  # 持久化封禁记录，避免重启后清空

[sshd]
enabled = true         # 启用对 SSH 服务的保护
port = ssh             # 保护的端口
logpath = /var/log/auth.log  # SSH 日志文件路径（Ubuntu 系统默认）

EOF

# 重启 Fail2Ban 服务以加载新配置
sudo systemctl restart fail2ban
sudo systemctl enable fail2ban

# 验证 Fail2Ban 状态
sudo fail2ban-client status sshd
