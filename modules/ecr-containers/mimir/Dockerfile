FROM grafana/mimir:latest

COPY mimir-config.yaml /etc/mimir/config.yaml

EXPOSE 8080

ENTRYPOINT ["/bin/mimir"]
CMD ["-config.file=/etc/mimir/config.yaml"]
