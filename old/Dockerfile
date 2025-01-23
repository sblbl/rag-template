# Dockerfile.ollama
FROM ollama/ollama:latest

# Install curl for healthcheck and model pulling
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*

# Copy initialization script
COPY init-ollama.sh /init-ollama.sh
RUN chmod +x /init-ollama.sh

# Use the initialization script as the entrypoint
ENTRYPOINT ["/init-ollama.sh"]