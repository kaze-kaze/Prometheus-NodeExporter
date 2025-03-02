# 获取 Prometheus 最新版本
github_project="prometheus/prometheus"
tag=$(wget -qO- -t1 -T2 "https://api.github.com/repos/${github_project}/releases/latest" | grep "tag_name" | head -n 1 | awk -F ":" '{print $2}' | sed 's/\"//g;s/,//g;s/ //g')

# 下载 Prometheus 最新版本并解压
wget https://github.com/prometheus/prometheus/releases/download/${tag}/prometheus-${tag#*v}.linux-amd64.tar.gz && \
tar xvfz prometheus-*.tar.gz && \
rm prometheus-*.tar.gz && cd prometheus-*.linux-amd64

# 将 Prometheus 可执行文件放入通用的系统目录下
sudo mv prometheus promtool /usr/local/bin/
sudo mkdir -p /etc/prometheus /var/lib/prometheus && \
sudo mv prometheus.yml /etc/prometheus/prometheus.yml
sudo mv consoles/ console_libraries/ /etc/prometheus/

# 清理
cd .. && rm -r prometheus-*.linux-amd64
# 创建一个系统用户 `prometheus` ，所有权分配
sudo useradd -rs /bin/false prometheus
sudo chown -R prometheus: /etc/prometheus /var/lib/prometheus

sudo cat > /etc/systemd/system/prometheus.service <<EOF
[Unit]
Description=Prometheus
Wants=network-online.target
After=network-online.target

[Service]
User=prometheus
Group=prometheus
Type=simple
Restart=on-failure
RestartSec=5s
ExecStart=/usr/local/bin/prometheus \
    --config.file /etc/prometheus/prometheus.yml \
    --storage.tsdb.path /var/lib/prometheus/ \
    --web.console.templates=/etc/prometheus/consoles \
    --web.console.libraries=/etc/prometheus/console_libraries \
    --web.listen-address=0.0.0.0:9090 \
    --web.enable-lifecycle \
    --log.level=info

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now prometheus
sudo systemctl status prometheus