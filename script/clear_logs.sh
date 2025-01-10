#!/bin/bash

# 清理 journal 日志：保留空间在 100MB 且保留过去 7 天的日志
journalctl --vacuum-size=100M
journalctl --vacuum-time=7d

# 清除过期日志文件
sudo rm -rf /var/log/*.gz
sudo rm -rf /var/log/*.1
sudo rm -rf /var/log/*.0
# 安装 Fail2Ban
