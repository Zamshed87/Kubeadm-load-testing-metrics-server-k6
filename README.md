# Kubernetes Cluster Setup – Master & Worker Node Join

## 1️⃣ Prepare the Master Node

### a) Open Required Ports in Security Group
In your cloud provider (e.g., AWS), edit the **Security Group** for the master node and allow inbound:

| Port   | Protocol | Purpose |
|--------|----------|--------------------------------|
| 6443   | TCP      | Kubernetes API server          |
| 2379–2380 | TCP   | etcd server client API         |
| 10250  | TCP      | Kubelet API                    |
| 10251  | TCP      | kube-scheduler                 |
| 10252  | TCP      | kube-controller-manager        |
| 10255  | TCP      | Read-only Kubelet API (optional) |

Also allow **ICMP (ping)** for troubleshooting.

### b) Enable IP Forwarding
Kubernetes requires IP forwarding to be enabled.

Enable immediately:
```bash
sudo sysctl -w net.ipv4.ip_forward=1
```

Make it persistent:
```bash
sudo nano /etc/sysctl.conf
```
Add or uncomment:
```
net.ipv4.ip_forward = 1
```

Reload settings:
```bash
sudo sysctl -p
```

Verify:
```bash
cat /proc/sys/net/ipv4/ip_forward
# Expected output: 1
```

---

## 2️⃣ Initialize the Control Plane

On the master node, run:
```bash
sudo kubeadm init   --apiserver-advertise-address=172.31.28.30   --pod-network-cidr=10.244.0.0/16   --upload-certs
```

Save the kubeadm join command from the output.  
Tokens expire after 24h — if needed, regenerate:
```bash
sudo kubeadm token create --print-join-command
```

---

## 3️⃣ Configure kubectl on the Master

Set up kubeconfig so you can run kubectl as a normal user:
```bash
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

Test:
```bash
kubectl get nodes
```

---

## 4️⃣ Copy Kubeconfig to Worker (Optional for kubectl)

If you want to run kubectl from the worker:

On the master:
```bash
sudo cat /etc/kubernetes/admin.conf
```

Copy the content.

On the worker:
```bash
nano ~/admin.conf   # paste the content
export KUBECONFIG=$HOME/admin.conf
echo 'export KUBECONFIG=$HOME/admin.conf' >> ~/.bashrc
```

Verify:
```bash
kubectl get nodes
kubectl get pods -A
```

✅ You should see the master node.

---

## 5️⃣ Join the Worker Node

Use the join command saved from the kubeadm init step. Run it with sudo:
```bash
sudo kubeadm join 172.31.28.30:6443   --token fjayi9.s56fl9bpqyk2fpar   --discovery-token-ca-cert-hash sha256:731fcbfc2a85c316724d92931514f9fff2473c6a400051a907703b28ebdaefdc
```

⚠️ If you forget sudo, you’ll see:
```
[ERROR IsPrivilegedUser]: user is not running as root
```

---

## 6️⃣ Verify the Node Status

On the master node:
```bash
kubectl get nodes -o wide
```

Example output:
```
NAME                     STATUS     ROLES           AGE     VERSION
zamshed-master-node      Ready      control-plane   10m     v1.33.5
zamshed-worker-node-1    NotReady   <none>          1m      v1.33.5
```

Nodes may show **NotReady** until you deploy a CNI plugin.

---

## 7️⃣ Deploy a Pod Network (CNI)

Install a network plugin, e.g., Flannel:
```bash
kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml
```

Check:
```bash
kubectl get pods -A
kubectl get nodes
```

Once the CNI is ready, worker nodes should move to **Ready**.

---

## ✅ Final Checklist

- [x] Security group allows required ports  
- [x] IP forwarding enabled  
- [x] kubeadm init completed  
- [x] kubeconfig set up  
- [x] Worker joined successfully  
- [x] CNI deployed  

---

## Debugging Metrics Server

```bash
kubectl -n kube-system rollout status deploy metrics-server
kubectl get apiservices | grep metrics
kubectl top nodes
kubectl top pods
```
