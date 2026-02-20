#!/bin/bash
# 定义镜像包路径（/mnt/hgfs  是虚拟机下linux的共享Windows的文件夹）
IMAGE_PATH="/mnt/hgfs/linux download/hello-world.tar"

# 检查文件是否存在
if [ ! -f "$IMAGE_PATH" ]; then
    echo "错误：未找到 hello-world.tar 文件，请检查路径！"
    exit 1
fi

# 导入镜像
echo "正在导入 hello-world 镜像..."
docker load -i "$IMAGE_PATH"

# 验证 Docker 是否正常运行
echo "正在运行 hello-world 容器..."
docker run --rm hello-world

# 检查运行结果
if [ $? -eq 0 ]; then
    echo -e "\n✅ Docker 安装成功！可以正常使用。"
else
    echo -e "\n❌ Docker 运行失败，请检查安装是否完整。"
fi