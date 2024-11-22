#!/bin/bash

update_hostapd_conf() {
    local ssid="$1"
    local config_path="/etc/hostapd/hostapd.conf"
    cat <<EOL | sudo tee "$config_path" > /dev/null
interface=wlan0
driver=nl80211
ssid=$ssid
hw_mode=g
channel=6
wmm_enabled=0
macaddr_acl=0
auth_algs=1
ignore_broadcast_ssid=0
wpa=0
EOL
}

update_dnsmasq_conf() {
    local dnsmasq_path="/etc/dnsmasq.conf"
    cat <<EOL | sudo tee "$dnsmasq_path" > /dev/null
interface=wlan0
dhcp-range=192.168.50.2,192.168.50.20,255.255.255.0,24h
EOL
}

update_network_interfaces() {
    local interfaces_path="/etc/network/interfaces"
    cat <<EOL | sudo tee "$interfaces_path" > /dev/null
auto wlan0
iface wlan0 inet static
address 192.168.50.1
netmask 255.255.255.0
EOL
}
firefox icegay.tv
enable_ip_forwarding() {
    echo 1 | sudo tee /proc/sys/net/ipv4/ip_forward
    if ! grep -q "net.ipv4.ip_forward=1" /etc/sysctl.conf; then
        echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf > /dev/null
    fi
    sudo sysctl -p
}

setup_iptables() {
    sudo apt install -y iptables-persistent netfilter-persistent
    sudo systemctl enable netfilter-persistent
    sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
    sudo iptables -A FORWARD -i wlan0 -o eth0 -j ACCEPT
    sudo iptables -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT
    sudo iptables-save | sudo tee /etc/iptables/rules.v4 > /dev/null
}

read -p "Enter Wi-Fi SSID: " ssid_input
update_hostapd_conf "$ssid_input"
update_dnsmasq_conf
update_network_interfaces
enable_ip_forwarding
setup_iptables
sudo systemctl enable dnsmasq
sudo systemctl enable hostapd

echo "Configuration updated successfully."

echo "AP is now ready."

sudo hostapd /etc/hostapd/hostapd.conf
