FROM debian:trixie-slim AS builder

COPY scripts/change_source.sh /scripts/change_source.sh
COPY config/sources.yaml      /config/sources.yaml
RUN chmod +x /scripts/change_source.sh

RUN bash /scripts/change_source.sh debian python