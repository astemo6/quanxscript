#!/bin/bash

# Function to ask whether to continue to the next module
ask_continue() {
    read -p "Do you want to continue to the next module? (y/n): " continue_answer
    if [ "$continue_answer" != "y" ]; then
        echo "Skipping remaining modules. Exiting script."
        exit 0
    fi
}

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
    ask_continue
}

# Function to change root password
change_root_password() {
    read -p "Do you want to change the root password? (y/n): " answer
    if [ "$answer" == "y" ]; then
        read -s -p "Enter new root password: " new_password1
        echo
        read -s -p "Re-enter new root password: " new_password2
        echo
        if [ "$new_password1" != "$new_password2" ]; then
            echo "Passwords do not match. Please try again."
            return
        fi
        echo "Attempting to change root password."
        echo "root:$new_password1" | sudo chpasswd
        if [ $? -eq 0 ]; then
            echo "Root password has been changed successfully."
        else
            echo "Failed to change root password."
        fi
    else
        echo "Root password remains unchanged."
    fi
    ask_continue
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
    ask_continue
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
    ask_continue
}

# Function to install x-ui
install_xui() {
    read -p "Do you want to install x-ui? (y/n): " install_xui_answer
    if [ "$install_xui_answer" == "y" ]; then
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
    else
        echo "Skipping x-ui installation."
    fi
    ask_continue
}

# Function to open ports, apply certificates, and configure auto-renewal
configure_ports_and_certificates() {
    echo "WARNING: The following operations will apply for SSL certificates. Please ensure that your domain name has been successfully resolved to this VPS."
    read -p "Press Enter to continue or Ctrl+C to cancel."

    # Ensure socat is installed
    if ! command -v socat &> /dev/null; then
        echo "Socat is not installed."
        read -p "Do you want to install socat now? (y/n): " install_socat
        install_socat=${install_socat,,}  # Convert to lowercase
        case $install_socat in
            y)
                echo "Installing socat..."
                sudo apt update -y && sudo apt install -y socat
                if [ $? -eq 0 ]; then
                    echo "Socat has been installed successfully."
                else
                    echo "Failed to install socat. Please check your system and try again."
                    exit 1
                fi
                ;;
            n)
                echo "Socat is required for certificate issuance. Exiting."
                exit 1
                ;;
            *)
                echo "Invalid choice. Exiting."
                exit 1
                ;;
        esac
    else
        echo "Socat is already installed."
    fi

    # Open port 80 and configure certificates
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

    # Configure crontab for automatic certificate renewal
    (crontab -l 2>/dev/null; echo "4 0 * * * \"/root/.acme.sh\"/acme.sh --cron --home \"/root/.acme.sh\" > /dev/null") | crontab -
    (crontab -l 2>/dev/null; echo "8 0 * * * /root/.acme.sh/acme.sh --install-cert -d $domain_name --key-file /root/private.key --fullchain-file /root/cert.crt --reloadcmd \"systemctl restart x-ui\"") | crontab -

    echo "Certificates and crontab auto-renewal configuration have been completed."
    ask_continue
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
    ask_continue
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
    ask_continue
}

# Main function
main() {
    update_environment
    change_root_password
    create_swap_partition
    install_docker
    install_xui
    configure_ports_and_certificates
    open_additional_ports
    enable_bbr
}

# Execute main function
main
