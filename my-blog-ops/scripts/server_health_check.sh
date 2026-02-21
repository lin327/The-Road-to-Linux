#!/bin/bash
# 服务器健康检测脚本（带日志）
# 日志文件路径
LOG_FILE="../logs/health_check_$(date +%Y%m%d).log"

# 输出日志函数
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" >> $LOG_FILE
}

log "========== 服务器健康检查开始 =========="

# 1. CPU使用率
CPU_USAGE=$(top -b -n 1 | grep "Cpu(s)" | awk '{print 100 - $8}')
log "CPU 使用率：${CPU_USAGE}%"
echo "CPU 使用率：${CPU_USAGE}%"

# 2. 内存使用率
MEM_TOTAL=$(free -h | grep Mem | awk '{print $2}')
MEM_USED=$(free -h | grep Mem | awk '{print $3}')
MEM_USAGE=$(free | grep Mem | awk '{print $3/$2*100}')
log "内存 使用率：已用 ${MEM_USED} / 总 ${MEM_TOTAL} (${MEM_USAGE}%)"
echo "内存 使用率：已用 ${MEM_USED} / 总 ${MEM_TOTAL} (${MEM_USAGE}%)"

# 3. 磁盘使用率（根目录）
DISK_USAGE=$(df -h | grep /dev/sda1 | awk '{print $5}')
log "磁盘 使用率（根目录）：${DISK_USAGE}"
echo "磁盘 使用率（根目录）：${DISK_USAGE}"

# 4. 关键端口检测（80/3306/8080）
check_port() {
    if netstat -anp | grep -q ":$1 "; then
        log "端口 $1: 正常监听"
        echo "端口 $1: ✅ 正常监听"
    else
        log "端口 $1: 未监听（异常）"
        echo "端口 $1: ❌ 未监听（异常）"
    fi
}
check_port 80
check_port 3306

log "========== 服务器健康检查结束 =========="
