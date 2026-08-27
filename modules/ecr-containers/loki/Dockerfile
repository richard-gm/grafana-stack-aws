FROM grafana/loki:latest

COPY loki-config.yaml /etc/loki/local-config.yaml

EXPOSE 3100

ENTRYPOINT ["/usr/bin/loki"]
CMD ["-config.file=/etc/loki/local-config.yaml"]
