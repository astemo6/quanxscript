#!/bin/bash

# Function to update components and configure environment
update_environment() {
    read -p "Are you sure you want to update components and configure environment? (y/n): " answer
    if [ "$answer" == "y" ]; then
        sudo apt update -y
        sudo apt install -y curl socat
        sudo timedatectl set-timezone "Asia/Shanghai"
        echo "update_environment completed."
    else
        echo "Skipping update_environment."
    fi
}

# Function to change root password
change_root_password() {
    read -p "Do you want to change the root password? (y/n): " answer
    if [ "$answer" == "y" ]; then
        read -s -p "Enter new root password: " new_password
        echo
        echo "Attempting to change root password to: $new_password"
        echo "root:$new_password" | sudo chpasswd
        if [ $? -eq 0 ]; then
            echo "Root password has been changed successfully."
        else
            echo "Failed to change root password."
        fi
    else
        echo "Root password remains unchanged."
    fi
}

# Function to create swap partition
create_swap_partition() {
    read -p "Do you want to create a swap partition? (y/n): " answer
    if [ "$answer" == "y" ]; then
        read -p "Enter swap size in MB (e.g., 1024): " swap_size_mb
        sudo fallocate -l ${swap_size_mb}M /swapfile
        sudo chmod 600 /swapfile
        sudo mkswap /swapfile
        sudo swapon /swapfile
        echo "/swapfile none swap sw 0 0" | sudo tee -a /etc/fstab
        echo "Swap partition has been created successfully."
    else
        echo "No swap partition created."
    fi
}

# Function to install Docker
install_docker() {
    read -p "Do you want to install Docker? (y/n): " answer
    if [ "$answer" == "y" ]; then
        read -p "Proceeding with Docker installation. Press Enter to continue or Ctrl+C to cancel."
        curl -fsSL https://get.docker.com -o get-docker.sh
        sudo sh get-docker.sh
        echo "Docker has been installed successfully."
    else
        echo "Docker installation skipped."
    fi
}

# Function to open ports, apply certificates, and configure auto-renewal
configure_ports_and_certificates() {
    read -p "Are you going to build x-ui on this VPS? (y/n): " answer
    if [ "$answer" == "y" ]; then
        echo "WARNING: The following operations will apply for SSL certificates. Please ensure that your domain name has been successfully resolved to this VPS."
        read -p "Press Enter to continue or Ctrl+C to cancel."
        sudo iptables -I INPUT -p tcp --dport 80 -j ACCEPT
        sudo iptables-save
        curl https://get.acme.sh | sudo sh
        sudo ~/.acme.sh/acme.sh --set-default-ca --server letsencrypt
        domain_name=""
        attempt=0
        while [ -z "$domain_name" ]; do
            read -p "Enter your domain name (e.g., example.com): " domain_name
            if [ -z "$domain_name" ]; then
                echo "Domain name cannot be empty. Please enter a valid domain name."
                attempt=$((attempt+1))
                if [ $attempt -eq 3 ]; then
                    read -p "Do you want to skip the SSL application for now? (y/n): " skip_ssl
                    if [ "$skip_ssl" == "y" ]; then
                        echo "Skipping SSL application."
                        return
                    elif [ "$skip_ssl" == "n" ]; then
                        attempt=0
                    else
                        echo "Invalid choice. Exiting."
                        exit 1
                    fi
                fi
            else
                sudo ~/.acme.sh/acme.sh --issue -d "$domain_name" --standalone --force
                if [ $? -ne 0 ]; then
                    echo "Certificate issuance failed for domain: $domain_name"
                    echo "Please check your domain name and try again."
                    domain_name=""
                fi
            fi
        done
        sudo ~/.acme.sh/acme.sh --installcert -d "$domain_name" --key-file /root/private.key --fullchain-file /root/cert.crt
        sudo ~/.acme.sh/acme.sh --upgrade --auto-upgrade
        echo "Certificates have been configured."
    else
        echo "Exiting the script."
        exit 0
    fi
}

# Function to open additional ports
open_additional_ports() {
    while true; do
        read -p "Do you want to open additional ports? (y/n): " answer
        if [ "$answer" == "y" ]; then
            read -p "Enter port numbers separated by commas (e.g., 8080,9090): " port_numbers
            IFS=',' read -ra ports <<< "$port_numbers"
            for port in "${ports[@]}"; do
                sudo iptables -I INPUT -p tcp --dport "$port" -j ACCEPT
                sudo iptables -I INPUT -p udp --dport "$port" -j ACCEPT
                echo "Port $port has been opened successfully."
            done
            sudo iptables-save
        else
            echo "No additional ports opened."
            break
        fi
    done
}

# Function to enable BBR
enable_bbr() {
    read -p "Do you want to enable BBR? (y/n): " answer
    if [ "$answer" == "y" ]; then
        read -p "Proceeding with enabling BBR. Press Enter to continue or Ctrl+C to cancel."
        echo "Enabling BBR..."
        echo "net.core.default_qdisc=fq" | sudo tee -a /etc/sysctl.conf
        echo "net.ipv4.tcp_congestion_control=bbr" | sudo tee -a /etc/sysctl.conf
        sudo sysctl -p
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
            exit 1
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
