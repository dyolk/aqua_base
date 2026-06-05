# syntax=docker/dockerfile:1
FROM debian:bookworm-slim AS builder

ARG NGINX_VERSION

RUN test -z "${NGINX_VERSION}" && { \
    echo -e "\n\033[1;31m+------------------------------------------------------------+\033[0m"; \
    echo -e "\033[1;31m| ❌【构建失败】错误时间: $(date '+%Y-%m-%d %H:%M:%S')             |\033[0m"; \
    echo -e "\033[1;31m+------------------------------------------------------------+\033[0m"; \
    echo -e "\033[1;31m| 📝 原因: 未检测到必要构建参数 'NGINX_VERSION'                  |\033[0m"; \
    echo -e "\033[1;33m| 💡 解决: 请在执行 docker build 时加上 --build-arg 选项         |\033[0m"; \
    echo -e "\033[1;32m|    示例: docker build --build-arg NGINX_VERSION=1.25.3 .   |\033[0m"; \
    echo -e "\033[1;31m+------------------------------------------------------------+\033[0m\n"; \
    exit 1; \
} || echo -e "\n\033[1;32m⚙️ 正在基于 Nginx 版本 [ ${NGINX_VERSION} ] 开始构建...\033[0m\n"

RUN apt-get -y update && apt-get -y upgrade

RUN <<EOF
set -e
EOF