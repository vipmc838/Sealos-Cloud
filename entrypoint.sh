#!/bin/sh

# 设置默认值
ARGO_DOMAIN=${ARGO_DOMAIN:-""}
ARGO_AUTH=${ARGO_AUTH:-""}
NZ_UUID=${NZ_UUID:-""}
NZ_CLIENT_SECRET=${NZ_CLIENT_SECRET:-kxU90rEPN7XsgDJp0qCG87UGdFYoTFkE}
NZ_TLS=${NZ_TLS:-false}
DASHBOARD_VERSION=${DASHBOARD_VERSION:-latest}

echo "配置定时备份任务..."
echo "0 2,14 * * * cd / && ./backup.sh backup >> /dashboard/backup.log 2>&1" > /var/spool/cron/crontabs/root

# 检查是否添加成功
if crontab -l | grep -q "cd / && ./backup.sh backup"; then
  echo "定时备份任务已添加成功"
else
  echo "定时备份任务添加失败"
fi

/backup.sh restore # 尝试恢复备份

echo "启动 crond"  # 启动 crond
crond

# 检查并生成证书
if [ -n "$ARGO_DOMAIN" ]; then
    echo "正在生成域名证书: $ARGO_DOMAIN"
    openssl genrsa -out /dashboard/nezha.key 2048
    openssl req -new -subj "/CN=$ARGO_DOMAIN" -key /dashboard/nezha.key -out /dashboard/nezha.csr
    openssl x509 -req -days 36500 -in /dashboard/nezha.csr -signkey /dashboard/nezha.key -out /dashboard/nezha.pem
else
    echo "警告: 未设置ARGO_DOMAIN，正在跳过证书生成"
fi

# 启动 Nginx
echo "启动 nginx..."
nginx -g "daemon off;" &
sleep 3

# 启动 cloudflared
if [ -n "$ARGO_AUTH" ]; then
    echo "启动 cloudflared..."
    cloudflared --no-autoupdate tunnel run --protocol http2 --token "$ARGO_AUTH" >/dev/null 2>&1 &
else
    echo "警告: 未设置 ARGO_AUTH，正在跳过执行 cloudflared"
fi
sleep 3

ARCH="linux_amd64"

if [ -z "$DASHBOARD_VERSION" ] || [ "$DASHBOARD_VERSION" = "latest" ]; then
  echo "未指定有效版本号，开始获取最新版本号..."
  DASHBOARD_VERSION=$(curl -s https://api.github.com/repos/nezhahq/agent/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
  if [ -z "$DASHBOARD_VERSION" ]; then
    echo "获取最新版本失败，退出"
    exit 1
  fi
  echo "最新版本号为: $DASHBOARD_VERSION"
else
  echo "使用指定版本号: $DASHBOARD_VERSION"
fi

FILE="nezha-agent_linux_amd64.zip"
URL="https://github.drny168.top/github.com/nezhahq/agent/releases/download/${DASHBOARD_VERSION}/${FILE}"

echo "下载探针: $URL"
curl -sSL -o "$FILE" "$URL"
if [ $? -ne 0 ] || [ ! -s "$FILE" ]; then
  echo "探针下载失败，跳过启动"
else
  unzip -qo "$FILE"
  if [ $? -ne 0 ]; then
    echo "解压失败，跳过继续执行"
  else
    chmod +x nezha-agent
    echo "探针下载并解压完成"
  fi
  rm -f "$FILE"
fi

# 创建探针配置文件
cat > config.yml <<EOF
client_secret: $NZ_CLIENT_SECRET
debug: false
disable_auto_update: true
disable_command_execute: false
disable_force_update: true
disable_nat: false
disable_send_query: false
gpu: false
insecure_tls: false
ip_report_period: 1800
report_delay: 4
server: $ARGO_DOMAIN:443
skip_connection_count: false
skip_procs_count: false
temperature: false
tls: ${NZ_TLS:-false}
use_gitee_to_upgrade: false
use_ipv6_country_code: false
uuid: $NZ_UUID
EOF

# 检查 nezha-agent 是否存在
if [ -f ./nezha-agent ]; then
    echo "启动探针..."
    nohup ./nezha-agent -c config.yml >/dev/null 2>&1 &
    sleep 3
    if pgrep -f "nezha-agent" >/dev/null; then
        echo "探针启动成功"
    else
        echo "探针启动失败"
    fi
else
    echo "未找到 nezha-agent 文件，跳过探针启动"
fi

echo "启动哪吒面板..."
echo "您可以通过 https://$ARGO_DOMAIN 访问 哪吒面板"
exec ./app
