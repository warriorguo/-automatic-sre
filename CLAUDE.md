# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Automatic SRE is an infrastructure automation project that uses Claude AI for intelligent Kubernetes cluster monitoring and remediation. The system monitors cluster health and can autonomously diagnose and fix issues.

## Infrastructure

**Kubernetes Cluster (v1.29.15):**
- Control plane: `n85` (SSH: `andrew@n85`, sudo password: `operation`)
- Worker node: `n169` (SSH: `andrew@n169`, sudo password: `operation`)

**Mac Server (192.168.0.151):**
- SSH: `liuli@192.168.0.151`
- Services: PostgreSQL@14, Kafka
- Brew path: `/usr/local/bin/brew`

## Key Commands

```bash
# Run health check
./local/scripts/k8s-health-check.sh

# Run health check with automatic Claude remediation
./local/scripts/k8s-health-check.sh --alert

# Check node status
ssh andrew@n85 "echo 'operation' | sudo -S kubectl --kubeconfig=/etc/kubernetes/admin.conf get nodes"

# Check all pods
ssh andrew@n85 "echo 'operation' | sudo -S kubectl --kubeconfig=/etc/kubernetes/admin.conf get pods -A"

# Check kubelet status
ssh andrew@n85 "echo 'operation' | sudo -S systemctl status kubelet --no-pager"

# Disable swap (required after power outage)
ssh andrew@n85 "echo 'operation' | sudo -S swapoff -a"
```

## Architecture

The health check script (`local/scripts/k8s-health-check.sh`) monitors four dimensions:
1. Node status (Ready/NotReady)
2. System pods (kube-system namespace)
3. Ingress controller (ingress-nginx namespace)
4. Application pods (default namespace)

When run with `--alert`, it invokes Claude CLI to diagnose and fix detected issues, referencing `local/servers.md` for infrastructure context.

## Important Files

- `local/servers.md` - Infrastructure documentation and incident history
- `local/scripts/k8s-health-check.sh` - Main health monitoring script
- `local/logs/k8s-health.log` - Health check output logs

## Known Issues

**Swap after power outage:** Kubernetes nodes may fail after power outage due to swap being re-enabled. Fix with `swapoff -a` on both n85 and n169.

**PostgreSQL lockfile:** After power outage, PostgreSQL may fail to start due to stale `postmaster.pid`. Remove `/usr/local/var/postgresql@14/postmaster.pid` and restart service.
