#!/bin/bash

# 定义需要修改的配置文件路径
config_file="/etc/fail2ban/jail.local"

# 更新 jail 配置
echo "[sshd]" > $config_file
echo "enabled = true" >> $config_file
echo "port    = ssh" >> $config_file
echo "filter  = sshd" >> $config_file
echo "logpath = /var/log/auth.log" >> $config_file
echo "bantime = -1" >> $config_file
echo "findtime = 20m" >> $config_file
echo "maxretry = 5" >> $config_file

# 重新启动 fail2ban 服务使配置生效
systemctl restart fail2ban

echo "Fail2ban jail rule updated and service restarted."
