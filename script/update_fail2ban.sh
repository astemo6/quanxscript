#!/bin/bash

# 检测 fail2ban 是否安装，如果未安装，则自动安装
if ! command -v fail2ban-client &> /dev/null; then
    echo "Fail2ban 未安装，正在安装..."
    sudo apt update && sudo apt install -y fail2ban
else
    echo "Fail2ban 已安装，跳过安装步骤。"
fi

# 配置 fail2ban 保护 SSH 端口 2520
config_file="/etc/fail2ban/jail.local"

echo "更新 fail2ban 配置..."
if ! grep -q "\[sshd\]" "$config_file"; then
    echo "[sshd]" | sudo tee -a $config_file
    echo "enabled = true" | sudo tee -a $config_file
    echo "port = 2520" | sudo tee -a $config_file
    echo "filter = sshd" | sudo tee -a $config_file
    echo "logpath = /var/log/auth.log" | sudo tee -a $config_file
    echo "bantime = -1" | sudo tee -a $config_file  # 永久封禁
    echo "findtime = 20m" | sudo tee -a $config_file  # 20 分钟内
    echo "maxretry = 10" | sudo tee -a $config_file  # 允许失败 10 次
else
    echo "SSH fail2ban 规则已存在，无需重复添加。"
fi

# 重新启动 fail2ban 服务使配置生效
echo "正在重启 fail2ban 服务..."
sudo systemctl restart fail2ban

# 显示 fail2ban 运行状态
echo "Fail2ban 运行状态："
sudo systemctl status fail2ban --no-pager

echo "Fail2ban 规则已更新：20 分钟内失败 10 次将被永久封禁！"
