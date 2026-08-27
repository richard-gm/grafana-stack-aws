FROM otel/opentelemetry-collector-contrib:latest

COPY otel-collector-config.yaml /etc/otelcol-contrib/config.yaml

EXPOSE 4317 4318 8888 8889

ENTRYPOINT ["/otelcol-contrib"]
CMD ["--config=/etc/otelcol-contrib/config.yaml"]
