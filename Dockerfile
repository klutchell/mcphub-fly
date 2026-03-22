FROM samanhappy/mcphub:0.12.9

# hadolint ignore=DL3008
RUN apt-get update \
  && apt-get install -y --no-install-recommends gettext-base \
  && rm -rf /var/lib/apt/lists/*

COPY mcp_settings.json /app/mcp_settings.json.template
COPY entrypoint-wrapper.sh /usr/local/bin/entrypoint-wrapper.sh
RUN chmod +x /usr/local/bin/entrypoint-wrapper.sh

ENTRYPOINT ["/usr/local/bin/entrypoint-wrapper.sh"]
CMD ["pnpm", "start"]
