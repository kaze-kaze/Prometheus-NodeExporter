#!/bin/bash
set -e

# 检查 root 权限
if [[ $EUID -ne 0 ]]; then
    echo "错误: 本脚本需要 root 权限，请使用 sudo 执行或在 root 用户下运行" >&2
    exit 1
fi

# 更新包列表
apt-get update -y

# 安装基础依赖
apt-get install -y \
    curl \
    sudo

# 添加 HTTPS 支持
apt-get install -y \
    apt-transport-https \
    software-properties-common

# 获取 Grafana 的 GPG 密钥
wget -q -O /usr/share/keyrings/grafana.key https://apt.grafana.com/gpg.key

# 添加 Grafana 软件源
echo "deb [signed-by=/usr/share/keyrings/grafana.key] https://apt.grafana.com stable main" \
    | tee -a /etc/apt/sources.list.d/grafana.list >/dev/null

# 更新并安装 Grafana
apt-get update -y
apt-get install -y grafana

# 服务管理
systemctl daemon-reload
systemctl enable --now grafana-server.service
systemctl start grafana-server
echo -e "\n服务状态检查:"
systemctl status grafana-server --no-pager