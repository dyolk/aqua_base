# syntax=docker/dockerfile:1
FROM debian:trixie-slim AS builder

COPY scripts/change_source.sh                   /dyolk/aqua_base/scripts/change_source.sh
COPY config/common/sources.yaml                 /dyolk/aqua_base/config/common/sources.yaml
COPY test/hashfiles                             /dyolk/aqua_base/test/hashfiles

RUN << EOF
chmod +x /dyolk/aqua_base/scripts/change_source.sh
bash /scripts/change_source.sh debian python
EOF