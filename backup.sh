#!/bin/sh

set -e

# === 必填环境变量 ===
WEBDAV_URL=${WEBDAV_URL:-"https://your-webdav-server/dav/backup/nezha/sealos"}
WEBDAV_USER=${WEBDAV_USER:-"your_username"}
WEBDAV_PASS=${WEBDAV_PASS:-"your_password"}

# 固定的备份文件名前缀
PREFIX="nezha_backup"

# 本地临时工作目录
TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"' EXIT

create_backup() {
    echo "开始创建备份..."

    [ ! -d "dashboard/data" ] && {
        echo "错误: dashboard/data 不存在"
        exit 1
    }

    TIMESTAMP=$(TZ='Asia/Shanghai' date +"%Y-%m-%d-%H-%M-%S")
    BACKUP_FILE="${PREFIX}-${TIMESTAMP}.tar.gz"
    BACKUP_PATH="${TEMP_DIR}/${BACKUP_FILE}"

    # 打包 data 目录
    tar -czf "$BACKUP_PATH" -C dashboard data
    echo "本地备份文件已生成: $BACKUP_FILE"

    # 上传到 WebDAV
    curl -s -u "$WEBDAV_USER:$WEBDAV_PASS" -T "$BACKUP_PATH" "$WEBDAV_URL/$BACKUP_FILE" \
        && echo "上传成功: $BACKUP_FILE" \
        || { echo "上传失败"; exit 1; }

    echo "开始清理 7 天前的旧备份..."

    NOW=$(date +%s)
    SEVEN_DAYS_AGO=$((NOW - 7*86400))

    # 列出并删除过期备份
    curl -s -u "$WEBDAV_USER:$WEBDAV_PASS" "$WEBDAV_URL/" \
      | grep -oE "${PREFIX}-[0-9]{4}-[0-9]{2}-[0-9]{2}-[0-9]{2}-[0-9]{2}-[0-9]{2}\.tar\.gz" \
      | while read -r file; do
          TS=$(echo "$file" \
            | sed -E "s/${PREFIX}-([0-9]{4})-([0-9]{2})-([0-9]{2})-([0-9]{2})-([0-9]{2})-([0-9]{2})\.tar\.gz/\1\2\3\4\5\6/")
          [ ${#TS} -ne 14 ] && continue
          FILE_EPOCH=$(date -u -d "${TS:0:4}-${TS:4:2}-${TS:6:2} ${TS:8:2}:${TS:10:2}:${TS:12:2}" +%s 2>/dev/null || echo 0)
          if [ "$FILE_EPOCH" -lt "$SEVEN_DAYS_AGO" ]; then
              echo "删除过期备份: $file"
              curl -s -u "$WEBDAV_USER:$WEBDAV_PASS" -X DELETE "$WEBDAV_URL/$file" > /dev/null
          fi
      done

    echo "备份流程完成"
}

restore_backup() {
    echo "当前路径: $(pwd)"
    echo "开始恢复最新备份..."

    latest_file=$(curl -s -u "$WEBDAV_USER:$WEBDAV_PASS" "$WEBDAV_URL/" \
      | grep -oE "${PREFIX}-[0-9]{4}-[0-9]{2}-[0-9]{2}-[0-9]{2}-[0-9]{2}-[0-9]{2}\.tar\.gz" \
      | sort -r | head -n 1)

    if [ -z "$latest_file" ]; then
        echo "未找到可用备份"
        exit 1
    fi

    echo "下载: $latest_file"
    curl -s -u "$WEBDAV_USER:$WEBDAV_PASS" -o "$TEMP_DIR/$latest_file" "$WEBDAV_URL/$latest_file" \
        || { echo "下载失败"; exit 1; }
        
    echo "清理旧 data 目录..."
    rm -rf data

    echo "解压到 dashboard/..."
    tar -xzf "$TEMP_DIR/$latest_file" -C .
    
    echo "data 目录内容:"
    ls -l data

    echo "恢复完成: $latest_file"
}

case "$1" in
    backup)
        create_backup
        ;;
    restore)
        restore_backup
        ;;
    *)
        echo "用法: $0 {backup|restore}"
        exit 1
        ;;
esac
