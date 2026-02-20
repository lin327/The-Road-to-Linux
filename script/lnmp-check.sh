#!/bin/bash
# LNMP 环境一键检测脚本
	
# 定义颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # 重置颜色

# 脚本标题
echo -e "${BLUE}========================================"
echo -e "          LNMP 环境检测脚本"
echo -e "========================================${NC}"
echo ""

# 1. 检查系统信息
echo -e "${BLUE}[1/5] 检测系统基础信息${NC}"
echo "系统发行版：$(cat /etc/os-release | grep PRETTY_NAME | cut -d= -f2 | sed 's/"//g')"
echo "内核版本：$(uname -r)"
echo "CPU 核心数：$(nproc)"
echo "内存总量：$(free -h | grep Mem | awk '{print $2}')"
echo ""

# 2. 检查 Nginx
echo -e "${BLUE}[2/5] 检测 Nginx 状态${NC}"
if command -v nginx &>/dev/null; then
    echo -e "${GREEN}✓ Nginx 已安装${NC}"
    echo "Nginx 版本：$(nginx -v 2>&1 | awk '{print $3}' | cut -d/ -f2)"
    # 检查运行状态
    if systemctl is-active --quiet nginx; then
        echo -e "${GREEN}✓ Nginx 运行中${NC}"
    else
        echo -e "${RED}✗ Nginx 未运行${NC}"
        echo "Nginx 状态详情：$(systemctl status nginx | grep Active:)"
    fi
    # 检查监听端口
    if netstat -tulpn | grep -q nginx; then
        echo "Nginx 监听端口：$(netstat -tulpn | grep nginx | awk '{print $4}' | uniq)"
    else
        echo -e "${YELLOW}⚠ Nginx 未监听任何端口${NC}"
    fi
else
    echo -e "${RED}✗ Nginx 未安装${NC}"
fi
echo ""

# 3. 检查 MySQL/MariaDB
echo -e "${BLUE}[3/5] 检测 MySQL/MariaDB 状态${NC}"
if command -v mysql &>/dev/null; then
    echo -e "${GREEN}✓ MySQL/MariaDB 已安装${NC}"
    # 区分 MySQL 和 MariaDB
    if mysql -V 2>&1 | grep -q MariaDB; then
        DB_TYPE="MariaDB"
        DB_VERSION=$(mysql -V 2>&1 | awk '{print $5}' | cut -d- -f1)
    else
        DB_TYPE="MySQL"
        DB_VERSION=$(mysql -V 2>&1 | awk '{print $5}' | cut -d. -f1-3)
    fi
    echo "${DB_TYPE} 版本：${DB_VERSION}"
    # 检查运行状态
    DB_SERVICE=$(systemctl list-unit-files | grep -E 'mysql|mariadb' | grep enabled | awk '{print $1}' | head -1)
    if [ -n "$DB_SERVICE" ] && systemctl is-active --quiet "$DB_SERVICE"; then
        echo -e "${GREEN}✓ ${DB_TYPE} 运行中${NC}"
        # 检查监听端口
        if netstat -tulpn | grep -q ":3306"; then
            echo "${DB_TYPE} 监听端口：3306"
        else
            echo -e "${YELLOW}⚠ ${DB_TYPE} 未监听 3306 端口${NC}"
        fi
    else
        echo -e "${RED}✗ ${DB_TYPE} 未运行${NC}"
        echo "${DB_TYPE} 状态详情：$(systemctl status $DB_SERVICE | grep Active: 2>/dev/null)"
    fi
else
    echo -e "${RED}✗ MySQL/MariaDB 未安装${NC}"
fi
echo ""

# 4. 检查 PHP
echo -e "${BLUE}[4/5] 检测 PHP 状态${NC}"
if command -v php &>/dev/null; then
    echo -e "${GREEN}✓ PHP 已安装${NC}"
    PHP_VERSION=$(php -v | head -1 | awk '{print $2}' | cut -d. -f1-2)
    echo "PHP 主版本：${PHP_VERSION}"
    # 检查 PHP-FPM 状态
    PHP_FPM_SERVICE=$(systemctl list-unit-files | grep php | grep fpm | grep enabled | awk '{print $1}' | head -1)
    if [ -n "$PHP_FPM_SERVICE" ] && systemctl is-active --quiet "$PHP_FPM_SERVICE"; then
        echo -e "${GREEN}✓ PHP-FPM 运行中${NC}"
        # 检查监听端口/套接字
        if netstat -tulpn | grep -q php-fpm; then
            echo "PHP-FPM 监听端口：$(netstat -tulpn | grep php-fpm | awk '{print $4}' | uniq)"
        else
            echo "PHP-FPM 监听套接字：$(grep listen /etc/php/*/fpm/pool.d/www.conf | grep -v ';' | awk '{print $2}')"
        fi
    else
        echo -e "${YELLOW}⚠ PHP-FPM 未运行或未安装${NC}"
    fi
    # 检查常用扩展
    echo "PHP 常用扩展检测："
    EXTENSIONS=("mysqli" "pdo_mysql" "gd" "curl" "mbstring" "redis")
    for ext in "${EXTENSIONS[@]}"; do
        if php -m | grep -q "$ext"; then
            echo -e "  ${GREEN}✓ $ext${NC}"
        else
            echo -e "  ${RED}✗ $ext${NC}"
        fi
    done
else
    echo -e "${RED}✗ PHP 未安装${NC}"
fi
echo ""

# 5. 检查 LNMP 联动
echo -e "${BLUE}[5/5] 检测 LNMP 联动性${NC}"
# 临时创建 PHP 测试文件
TEST_FILE="/tmp/lnmp_test.php"
cat > "$TEST_FILE" << EOF
<?php
phpinfo();
EOF
# 检查 Nginx 是否能解析 PHP
if command -v nginx &>/dev/null && command -v php &>/dev/null; then
    if curl -s http://127.0.0.1/lnmp_test.php 2>/dev/null | grep -q "PHP Version"; then
        echo -e "${GREEN}✓ Nginx 可正常解析 PHP${NC}"
    else
        echo -e "${YELLOW}⚠ Nginx 解析 PHP 失败（可能无默认站点/配置错误）${NC}"
    fi
else
    echo -e "${YELLOW}⚠ Nginx/PHP 未安装，跳过联动检测${NC}"
fi
# 删除测试文件
rm -f "$TEST_FILE"

echo ""
echo -e "${BLUE}========================================"
echo -e "          检测完成！"
echo -e "========================================${NC}"