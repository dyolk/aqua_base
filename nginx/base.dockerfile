# syntax=docker/dockerfile:1
FROM debian:trixie-slim AS builder

ARG NGINX_VERSION

COPY sources.toml /tmp/sources.toml

RUN <<EOF
set -e

if [ -z "${NGINX_VERSION}" ]; then
    printf "\n\033[1;31m+------------------------------------------------------------+\033[0m\n"
    printf "\033[1;31m| ❌ 【构建失败】未检测到必要构建参数 'NGINX_VERSION'         |\033[0m\n"
    printf "\033[1;31m+------------------------------------------------------------+\033[0m\n\n"
    exit 1
fi

. /etc/os-release
OS_ID="${ID}"
OS_CODENAME="${VERSION_CODENAME}"

tr -d '\r' < /tmp/sources.toml > /tmp/pure.toml

LINE_NUM=$(grep -n "${OS_CODENAME}" /tmp/pure.toml | grep "=" | cut -d':' -f1 | head -n1)

if [ -z "${LINE_NUM}" ]; then
    printf "\n\033[1;31m❌【换源失败】在 sources.toml 中根本找不到包含 [%s] 关键字的有效行！\033[0m\n" "${OS_CODENAME}"
    printf "📄 当前 pure.toml 完整内容如下，请肉眼核对：\n"
    cat /tmp/pure.toml
    exit 1
fi

RAW_ROW=$(sed -n "${LINE_NUM}p" /tmp/pure.toml)

RAW_LINE=$(echo "${RAW_ROW}" | awk -F'"' '{print $(NF-1)}')

TARGET_PATH=$(echo "${RAW_LINE}" | cut -d'|' -f1 | xargs)
SOURCE_CONTENT=$(echo "${RAW_LINE}" | cut -d'|' -f2- | xargs)

if [ -z "${TARGET_PATH}" ] || [ -z "${SOURCE_CONTENT}" ]; then
    printf "\n\033[1;31m❌【解析失败】成功找到了行，但没办法从中切出路径和内容！\033[0m\n"
    printf "🔍 抓到的原始行: [%s]\n" "${RAW_ROW}"
    printf "🔍 解析出的内容: [%s]\n" "${RAW_LINE}"
    exit 1
fi

rm -rf /etc/apt/sources.list /etc/apt/sources.list.d/*

mkdir -p "$(dirname "${TARGET_PATH}")"

if [ "${OS_ID}" = "alpine" ]; then
    echo "${SOURCE_CONTENT}" | tr ';' '\n' > "${TARGET_PATH}"
else
    echo "${SOURCE_CONTENT}" > "${TARGET_PATH}"
fi

rm -f /tmp/sources.toml /tmp/pure.toml
EOF

RUN <<EOF
set -e

apt-get update
apt-get upgrade -y --no-install-recommends
apt-get install -y --no-install-recommends \
    wget \
    build-essential
apt-get clean
rm -rf /var/lib/apt/lists/*
EOF
