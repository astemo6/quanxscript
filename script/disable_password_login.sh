# 设置root密码（可选）
# echo root:YourRootPasswd | sudo chpasswd

# 禁用root登录
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

# log清除
sudo truncate -s 0 /var/log/auth.log
sudo rm -rf /var/log/*.gz
sudo rm -rf /var/log/*.1
sudo rm -rf /var/log/*.0
