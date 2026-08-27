FROM grafana/grafana:latest

COPY grafana.ini /etc/grafana/grafana.ini

EXPOSE 3000

USER root

RUN mkdir -p /var/lib/grafana/plugins && \
    chown -R grafana:grafana /var/lib/grafana

USER grafana
