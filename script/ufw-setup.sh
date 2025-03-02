#!/bin/bash

# 定义颜色代码
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # 重置颜色

# 检查是否为root用户
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}错误：请使用sudo或以root用户身份运行该脚本${NC}"
    exit 1
fi

# 验证IPv4地址函数
validate_ipv4() {
    local ip=$1
    local stat=1
    
    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        OIFS=$IFS
        IFS='.'
        ip=($ip)
        IFS=$OIFS
        [[ ${ip[0]} -le 255 && ${ip[1]} -le 255 && \
           ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
        stat=$?
    fi
    return $stat
}

# 验证端口号函数
validate_port() {
    local port=$1
    [[ $port =~ ^[0-9]+$ ]] && [ "$port" -ge 1 -a "$port" -le 65535 ]
}

# 检查UFW是否安装
if dpkg -l | grep -q ufw; then
    echo -e "${YELLOW}警告：检测到系统已安装UFW防火墙${NC}"
    echo -e "${YELLOW}继续操作将会修改现有防火墙规则！${NC}"
    
    while true; do
        read -p "是否继续？(y/n) " yn
        case $yn in
            [Yy]* ) break;;
            [Nn]* ) exit;;
            * ) echo "请输入 y 或 n";;
        esac
    done
else
    apt-get update
    apt-get install -y ufw
fi

# 获取并验证白名单IP
while true; do
    read -p "请输入白名单IP地址： " ip
    if validate_ipv4 $ip; then
        break
    else
        echo -e "${RED}错误：无效的IPv4地址格式，请重新输入${NC}"
    fi
done

# 获取并验证端口号
port=9100
read -p "请输入要开放的端口号（默认9100）： " user_port
if [ ! -z "$user_port" ]; then
    if validate_port $user_port; then
        port=$user_port
    else
        echo -e "${RED}错误：无效端口号，使用默认9100端口${NC}"
    fi
fi

# 最终确认
echo -e "${YELLOW}即将执行以下操作："
echo "----------------------------------"
echo "1. 设置默认允许所有传入连接"
echo "2. 开放端口：${port}/tcp"
echo "3. 允许的IP地址：${ip}"
echo "4. 禁止其他所有地址访问${port}/tcp"
echo -e "----------------------------------${NC}"

while true; do
    read -p "确认执行配置？(y/n) " yn
    case $yn in
        [Yy]* ) break;;
        [Nn]* ) exit;;
        * ) echo "请输入 y 或 n";;
    esac
done

# 执行配置命令
echo -e "${GREEN}正在配置防火墙...${NC}"
{
    ufw default allow incoming
    ufw allow from $ip proto tcp to any port $port
    ufw deny proto tcp to any port $port
    echo y | ufw enable
} && echo -e "${GREEN}配置成功完成！${NC}" || echo -e "${RED}配置过程中出现错误！${NC}"

# 显示最终规则
echo -e "\n当前防火墙规则："
ufw status numbered