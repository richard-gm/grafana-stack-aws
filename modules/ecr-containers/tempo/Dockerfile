FROM grafana/tempo:latest

COPY tempo-config.yaml /etc/tempo/config.yaml

EXPOSE 3200

ENTRYPOINT ["/tempo"]
CMD ["-config.file=/etc/tempo/config.yaml"]
