clear
ls
hostnamectl set-hostname controlpanel
ls
clear
hostnamectl set-hostname controlpanel
sudo hostnamectl set-hostname controlpanel
clear
sudo apt-get update
# apt-transport-https may be a dummy package; if so, you can skip that package
sudo apt-get install -y apt-transport-https ca-certificates curl gpg
# If the directory `/etc/apt/keyrings` does not exist, it should be created before the curl command, read the note below.
# sudo mkdir -p -m 755 /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.34/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
# This overwrites any existing configuration in /etc/apt/sources.list.d/kubernetes.list
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.34/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
# Install kubelet, kubeadm, and kubectl
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl
kubeadm version
clear
sudo apt install containerd -y
sudo mkdir -p /etc/containerd
# Generate default config and enable systemd cgroup driver
containerd config default | sed 's/SystemdCgroup = false/SystemdCgroup = true/' | sudo tee /etc/containerd/config.toml
# Verify
cat /etc/containerd/config.toml | grep -i SystemdCgroup
# Restart containerd
sudo systemctl restart containerd
clear
# Load module now
sudo modprobe br_netfilter
# Make sure it loads on boot
echo "br_netfilter" | sudo tee /etc/modules-load.d/br_netfilter.conf
# Add missing sysctl params
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
EOF

# Apply immediately
sudo sysctl --system
clear
# Load module now
sudo modprobe br_netfilter
# Make sure it loads on boot
echo "br_netfilter" | sudo tee /etc/modules-load.d/br_netfilter.conf
# Add missing sysctl params
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
EOF

# Apply immediately
sudo sysctl --system
ps -p 1
clear
sudo sysctl -w net.ipv4.ip_forward=1
sudo nano /etc/sysctl.conf
sudo sysctl -p
