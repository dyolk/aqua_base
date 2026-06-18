#!/usr/bin/env bash
# ============================================================
# Aqua Base - 换源脚本
# ============================================================
# 用法:
#   change_source.sh <target>... [--config /path/to/sources.yaml]
#
#   target: debian | alpine | python | ...  (可指定多个)
#   --config: 指定 sources.yaml 路径 (默认 /config/sources.yaml)
#
# 示例:
#   change_source.sh debian                     # 只换 debian 源
#   change_source.sh debian python              # 同时换 debian 和 python 源
#   change_source.sh debian alpine python       # 全换
#   change_source.sh debian --config ./sources.yaml
#
# 依赖: yq
# ============================================================

set -euo pipefail

# ---- 默认值 ----
YQ="${YQ_BIN:-yq}"
SOURCES_FILE="/dyolk/aqua_base/config/common/sources.yaml"
TARGETS=()

# ---- 解析参数 ----
ARGS=("$@")
i=0
while [ $i -lt ${#ARGS[@]} ]; do
    case "${ARGS[$i]}" in
        --config)
            SOURCES_FILE="${ARGS[$((i+1))]}"
            i=$((i+2))
            ;;
        *)
            TARGETS+=("${ARGS[$i]}")
            i=$((i+1))
            ;;
    esac
done

if [ ${#TARGETS[@]} -eq 0 ]; then
    echo "[ERROR] No targets specified." >&2
    echo "Usage: $0 <target> [target...] [--config /path/to/sources.yaml]" >&2
    echo "  target: debian | alpine | python | ..." >&2
    exit 1
fi

if [ ! -f "$SOURCES_FILE" ]; then
    echo "[ERROR] sources file not found: $SOURCES_FILE" >&2
    exit 1
fi

# ---- 读取系统信息 ----
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS_ID="${ID:-}"
    OS_CODENAME="${VERSION_CODENAME:-}"
fi

# ---- 函数: 写入源文件 ----
write_source() {
    local path="$1"
    local content="$2"

    if [ -z "$path" ] || [ "$path" = "null" ]; then
        echo "[WARN] path is empty, skipping" >&2
        return
    fi
    if [ -z "$content" ]; then
        echo "[WARN] content is empty, skipping" >&2
        return
    fi

    mkdir -p "$(dirname "$path")"
    echo "$content" > "$path"
    echo "[OK]  ${path}"
    echo "$content" | while IFS= read -r line; do
        echo "      ${line}"
    done
}

# ---- 处理 os 源 (debian/ubuntu/alpine) ----
handle_os() {
    local target="$1"

    if [ -z "${OS_ID:-}" ] || [ -z "${OS_CODENAME:-}" ]; then
        echo "[WARN] ${target}: cannot detect OS from /etc/os-release, skipping" >&2
        return
    fi

    if [ "$target" != "$OS_ID" ]; then
        echo "[INFO] ${target}: current OS is ${OS_ID}, skipping" >&2
        return
    fi

    local path urls
    path=$("$YQ" eval ".os.${OS_ID}.\"${OS_CODENAME}\".path" "$SOURCES_FILE" 2>/dev/null)
    urls=$("$YQ" eval ".os.${OS_ID}.\"${OS_CODENAME}\".urls[]" "$SOURCES_FILE" 2>/dev/null)

    if [ -z "$path" ] || [ "$path" = "null" ]; then
        echo "[WARN] ${target}: codename '${OS_CODENAME}' not found" >&2
        return
    fi

    write_source "$path" "$urls"
}

# ---- 处理 runtime 源 (python/node/go/...) ----
handle_runtime() {
    local target="$1"

    local path urls
    path=$("$YQ" eval ".runtime.${target}.all.path" "$SOURCES_FILE" 2>/dev/null)
    urls=$("$YQ" eval ".runtime.${target}.all.urls[]" "$SOURCES_FILE" 2>/dev/null)

    if [ -z "$path" ] || [ "$path" = "null" ]; then
        echo "[WARN] ${target}: no 'all' config found" >&2
        return
    fi

    write_source "$path" "$urls"
}

# ---- 分类：os / runtime ----
OS_TARGETS="debian ubuntu alpine"

# ---- 主流程 ----
echo "[INFO] Config: ${SOURCES_FILE}"
echo "[INFO] Targets: ${TARGETS[*]}"

for target in "${TARGETS[@]}"; do
    echo ""
    echo "---- ${target} ----"

    if echo "$OS_TARGETS" | grep -qw "$target"; then
        handle_os "$target"
    else
        handle_runtime "$target"
    fi
done

echo ""
echo "[INFO] Done."
