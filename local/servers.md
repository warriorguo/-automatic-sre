# 服务器信息

## 192.168.0.151 (Mac - PostgreSQL)

- **SSH**: `ssh liuli@192.168.0.151`
- **用户**: liuli
- **系统**: macOS
- **服务**: PostgreSQL@14, Kafka
- **Brew路径**: `/usr/local/bin/brew`

### 常用命令
```bash
# 查看服务状态
ssh liuli@192.168.0.151 "/usr/local/bin/brew services list"

# 重启PostgreSQL
ssh liuli@192.168.0.151 "/usr/local/bin/brew services restart postgresql@14"

# 连接PostgreSQL
ssh liuli@192.168.0.151 "/usr/local/opt/postgresql@14/bin/psql -l"
```

---

## n85 (Kubernetes Control Plane)

- **SSH**: `ssh andrew@n85`
- **用户**: andrew
- **sudo密码**: operation
- **角色**: Kubernetes control-plane 节点
- **Kubernetes版本**: v1.29.15

## n169 (Kubernetes Worker Node)

- **SSH**: `ssh andrew@n169`
- **用户**: andrew
- **sudo密码**: operation
- **角色**: Kubernetes worker 节点
- **运行服务**: ingress-nginx-controller

## 常用命令

```bash
# 检查kubelet状态
ssh andrew@n85 "echo 'operation' | sudo -S systemctl status kubelet --no-pager"

# 查看节点状态
ssh andrew@n85 "echo 'operation' | sudo -S kubectl --kubeconfig=/etc/kubernetes/admin.conf get nodes"

# 查看所有Pod
ssh andrew@n85 "echo 'operation' | sudo -S kubectl --kubeconfig=/etc/kubernetes/admin.conf get pods -A"

# 关闭swap (kubelet需要)
ssh andrew@n85 "echo 'operation' | sudo -S swapoff -a"
```

## 故障排查记录

### 2026-01-30: 掉电后k8s无法启动
- **原因**: 重启后swap自动挂载，kubelet不支持swap
- **影响节点**: n85, n169（两台都有此问题）
- **解决**:
  1. `swapoff -a` 关闭swap
  2. 注释 `/etc/fstab` 中的swap条目防止重启后再次启用

```bash
# 快速修复命令（两台机器都需要执行）
ssh andrew@n85 "echo 'operation' | sudo -S swapoff -a && echo 'operation' | sudo -S sed -i 's|^/swap.img|#/swap.img|' /etc/fstab"
ssh andrew@n169 "echo 'operation' | sudo -S swapoff -a && echo 'operation' | sudo -S sed -i 's|^/swap.img|#/swap.img|' /etc/fstab"
```

### 2026-01-30: PostgreSQL无法启动 (192.168.0.151)
- **原因**: 掉电后残留 postmaster.pid 锁文件
- **解决**:
  1. 删除锁文件: `rm /usr/local/var/postgresql@14/postmaster.pid`
  2. 重启服务: `/usr/local/bin/brew services restart postgresql@14`
