#!/bin/bash

# 检测 fail2ban 是否已安装，如果未安装则自动安装
if ! command -v fail2ban-client &> /dev/null; then
    echo "Fail2ban 未安装，正在安装..."
    sudo apt update && sudo apt install -y fail2ban
else
    echo "Fail2ban 已安装，跳过安装步骤。"
fi

# 备份原来的 jail.local 文件
if [ -f /etc/fail2ban/jail.local ]; then
    sudo cp /etc/fail2ban/jail.local /etc/fail2ban/jail.local.bak
    echo "已备份原有 jail.local 为 jail.local.bak"
fi

# 更新 fail2ban 配置，覆盖原有 jail.local 规则
echo "更新 fail2ban 规则..."
sudo bash -c 'cat > /etc/fail2ban/jail.local <<EOF
[sshd]
enabled = true
port    = 2520
filter  = sshd
logpath = /var/log/auth.log
bantime = -1
findtime = 20m
maxretry = 10
EOF'

# 重启 fail2ban 服务使配置生效
echo "正在重启 fail2ban 服务..."
sudo systemctl restart fail2ban

# 显示 fail2ban 运行状态
echo "Fail2ban 运行状态："
sudo systemctl status fail2ban --no-pager

echo "Fail2ban 规则已更新：20 分钟内失败 10 次将被永久封禁！"
