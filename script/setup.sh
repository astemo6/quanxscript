#!/bin/bash

# Function to update components and configure environment
update_environment() {
    read -p "Are you sure you want to update components and configure environment? (yes/no): " answer
    if [ "$answer" == "yes" ]; then
        sudo -i
        apt update -y
        apt install -y curl socat
        timedatectl set-timezone "Asia/Shanghai"
    else
        echo "Skipping update_environment."
    fi
}

# Function to change root password
change_root_password() {
    read -p "Do you want to change the root password? (yes/no): " answer
    if [ "$answer" == "yes" ]; then
        read -s -p "Enter new root password: " new_password
        echo
        echo "root:$new_password" | chpasswd
        echo "Root password has been changed successfully."
    else
        echo "Root password remains unchanged."
    fi
}

# Function to create swap partition
create_swap_partition() {
    read -p "Do you want to create a swap partition? (yes/no): " answer
    if [ "$answer" == "yes" ]; then
        read -p "Enter swap size in GB (e.g., 1): " swap_size
        fallocate -l ${swap_size}G /swapfile
        chmod 600 /swapfile
        mkswap /swapfile
        swapon /swapfile
        echo "/swapfile none swap sw 0 0" >> /etc/fstab
        echo "Swap partition has been created successfully."
    else
        echo "No swap partition created."
    fi
}

# Function to install Docker
install_docker() {
    read -p "Do you want to install Docker? (yes/no): " answer
    if [ "$answer" == "yes" ]; then
        read -p "Proceeding with Docker installation. Press Enter to continue or Ctrl+C to cancel."
        curl -fsSL https://get.docker.com -o get-docker.sh
        sh get-docker.sh
        echo "Docker has been installed successfully."
    else
        echo "Docker installation skipped."
    fi
}

# Function to open ports, apply certificates, and configure auto-renewal
configure_ports_and_certificates() {
    read -p "Are you going to build x-ui on this VPS? (yes/no): " answer
    if [ "$answer" == "yes" ]; then
        echo "WARNING: The following operations will apply for SSL certificates. Please ensure that your domain name has been successfully resolved to this VPS."
        read -p "Press Enter to continue or Ctrl+C to cancel."
        iptables -I INPUT -p tcp --dport 80 -j ACCEPT
        iptables-save
        curl https://get.acme.sh | sh
        ~/.acme.sh/acme.sh --set-default-ca --server letsencrypt
        read -p "Enter your domain name (e.g., example.com): " domain_name
        ~/.acme.sh/acme.sh --issue -d "$domain_name" --standalone --force
        ~/.acme.sh/acme.sh --installcert -d "$domain_name" --key-file /root/private.key --fullchain-file /root/cert.crt
        ~/.acme.sh/acme.sh --upgrade --auto-upgrade
    else
        echo "Continuing without configuring ports and certificates."
    fi
}

# Function to open additional ports
open_additional_ports() {
    while true; do
        read -p "Do you want to open additional ports? (yes/no): " answer
        if [ "$answer" == "yes" ]; then
            read -p "Enter port numbers separated by commas (e.g., 8080,9090): " port_numbers
            IFS=',' read -ra ports <<< "$port_numbers"
            for port in "${ports[@]}"; do
                iptables -I INPUT -p tcp --dport "$port" -j ACCEPT
                iptables -I INPUT -p udp --dport "$port" -j ACCEPT
                echo "Port $port has been opened successfully."
            done
            iptables-save
        else
            echo "No additional ports opened."
            break
        fi
    done
}

# Function to enable BBR
enable_bbr() {
    read -p "Do you want to enable BBR? (yes/no): " answer
    if [ "$answer" == "yes" ]; then
        read -p "Proceeding with enabling BBR. Press Enter to continue or Ctrl+C to cancel."
        echo "Enabling BBR..."
        echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
        echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
        sysctl -p
        echo "BBR has been enabled successfully."
    else
        echo "BBR installation skipped."
    fi
}

# Function to install x-ui
install_xui() {
    read -p "Which x-ui version do you want to install?
    1. x-ui_FranzKafkaYu
    2. 3x-ui_MHSanaei
    Enter your choice (1/2): " xui_version
    case $xui_version in
        1)
            read -p "Proceeding with x-ui_FranzKafkaYu installation. Press Enter to continue or Ctrl+C to cancel."
            bash <(curl -Ls https://raw.githubusercontent.com/FranzKafkaYu/x-ui/master/install.sh)
            ;;
        2)
            read -p "Proceeding with 3x-ui_MHSanaei installation. Press Enter to continue or Ctrl+C to cancel."
            bash <(curl -Ls https://raw.githubusercontent.com/mhsanaei/3x-ui/master/install.sh)
            ;;
        *)
            echo "Invalid choice. Exiting."
            ;;
    esac
}

# Main function
main() {
    update_environment
    change_root_password
    create_swap_partition
    install_docker
    configure_ports_and_certificates
    open_additional_ports
    enable_bbr
    install_xui
}

# Execute main function
main
