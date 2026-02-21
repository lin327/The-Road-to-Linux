#!/bin/bash
# MySQL定时备份脚本
BACKUP_DIR="../backup"
# 备份文件名（带时间戳）
BACKUP_FILE="${BACKUP_DIR}/wordpress_$(date +%Y%m%d_%H%M%S).sql"
# Docker容器中的MySQL用户名/密码（后续部署会用到）
MYSQL_USER="root"
MYSQL_PASS="123456"
MYSQL_CONTAINER="my-blog-mysql"

# 创建备份目录（如果不存在）
mkdir -p $BACKUP_DIR

# 从Docker容器中备份MySQL
docker exec $MYSQL_CONTAINER mysqldump -u$MYSQL_USER -p$MYSQL_PASS wordpress > $BACKUP_FILE

# 压缩备份文件（节省空间）
gzip $BACKUP_FILE

# 删除7天前的备份文件（避免磁盘占满）
find $BACKUP_DIR -name "wordpress_*.sql.gz" -mtime +7 -delete

# 输出日志
echo "[$(date)] 备份完成：${BACKUP_FILE}.gz" >> ../logs/mysql_backup.log
