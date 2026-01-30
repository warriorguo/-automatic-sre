#!/bin/bash
# Kubernetes 健康检查脚本
# 用法: ./k8s-health-check.sh [autofix]

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

LOG_FILE="$SRE_DIR/logs/k8s-health.log"
ALERT_MODE="${1:-}"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
SSH_CMD="ssh andrew@n85"
KUBECTL="echo 'operation' | sudo -S kubectl --kubeconfig=/etc/kubernetes/admin.conf"

# 确保日志目录存在
mkdir -p "$(dirname "$LOG_FILE")"

# 问题收集
ISSUES=""

# 检查函数
check_nodes() {
    local result=$($SSH_CMD "$KUBECTL get nodes --no-headers 2>/dev/null")
    local has_issue=0
    while read name status roles age version; do
        if [ -n "$name" ] && [ "$status" != "Ready" ]; then
            echo "CRITICAL: Node $name is $status"
            ISSUES="${ISSUES}Node $name is $status. "
            has_issue=1
        fi
    done <<< "$result"

    if [ $has_issue -eq 0 ]; then
        echo "OK: All nodes are Ready"
    fi
    return $has_issue
}

check_system_pods() {
    local unhealthy_pods=$($SSH_CMD "$KUBECTL get pods -n kube-system --no-headers 2>/dev/null" | grep -v "Running\|Completed")
    local unhealthy=$(echo "$unhealthy_pods" | grep -c .)
    if [ "$unhealthy" -gt 0 ]; then
        echo "WARNING: $unhealthy unhealthy pods in kube-system"
        echo "$unhealthy_pods"
        ISSUES="${ISSUES}kube-system has $unhealthy unhealthy pods. "
        return 1
    fi
    echo "OK: All system pods healthy"
}

check_ingress() {
    local ingress_ready=$($SSH_CMD "$KUBECTL get pods -n ingress-nginx --no-headers 2>/dev/null" | grep "1/1.*Running" | wc -l)
    if [ "$ingress_ready" -lt 1 ]; then
        echo "CRITICAL: Ingress controller not ready"
        ISSUES="${ISSUES}Ingress controller not ready. "
        return 1
    fi
    echo "OK: Ingress controller running"
}

check_app_pods() {
    local unhealthy_pods=$($SSH_CMD "$KUBECTL get pods -n default --no-headers 2>/dev/null" | grep -v "Running\|Completed")
    local unhealthy=$(echo "$unhealthy_pods" | grep -c .)
    if [ "$unhealthy" -gt 0 ]; then
        echo "WARNING: $unhealthy unhealthy pods in default namespace"
        echo "$unhealthy_pods"
        ISSUES="${ISSUES}default namespace has $unhealthy unhealthy pods. "
        return 1
    fi
    echo "OK: All application pods healthy"
}

# 调用 Claude 修复
call_claude_fix() {
    local issues="$1"
    echo "[$TIMESTAMP] Calling Claude to fix issues..." | tee -a "$LOG_FILE"

    # 构建修复提示
    local prompt="K8s健康检查发现以下问题，请诊断并修复：${issues} 参考 servers.md 中的服务器信息和历史故障记录。"

    # 调用 Claude（在 SRE 目录下运行，可访问配置）
    cd "$SRE_DIR"
    ~/.local/bin/claude -p "$prompt" --allowedTools "Bash(ssh *)" 2>&1 | tee -a "$LOG_FILE"

    echo "[$TIMESTAMP] Claude fix attempt completed" | tee -a "$LOG_FILE"
}

# 执行检查
echo "========================================" | tee -a "$LOG_FILE"
echo "[$TIMESTAMP] K8s Health Check" | tee -a "$LOG_FILE"
echo "========================================" | tee -a "$LOG_FILE"

ERRORS=0

echo "" | tee -a "$LOG_FILE"
echo "[Nodes]" | tee -a "$LOG_FILE"
check_nodes | tee -a "$LOG_FILE" || ((ERRORS++))

echo "" | tee -a "$LOG_FILE"
echo "[System Pods]" | tee -a "$LOG_FILE"
check_system_pods | tee -a "$LOG_FILE" || ((ERRORS++))

echo "" | tee -a "$LOG_FILE"
echo "[Ingress]" | tee -a "$LOG_FILE"
check_ingress | tee -a "$LOG_FILE" || ((ERRORS++))

echo "" | tee -a "$LOG_FILE"
echo "[Application Pods]" | tee -a "$LOG_FILE"
check_app_pods | tee -a "$LOG_FILE" || ((ERRORS++))

echo "" | tee -a "$LOG_FILE"
if [ $ERRORS -gt 0 ]; then
    echo "[$TIMESTAMP] STATUS: UNHEALTHY ($ERRORS issues found)" | tee -a "$LOG_FILE"

    # 如果是告警模式，调用 Claude 尝试修复
    if [ "$ALERT_MODE" == "autofix" ]; then
        call_claude_fix "$ISSUES"
    fi
    exit 1
else
    echo "[$TIMESTAMP] STATUS: HEALTHY" | tee -a "$LOG_FILE"
    exit 0
fi
