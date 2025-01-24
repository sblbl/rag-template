#!/bin/bash

# Start Ollama service if not running
if ! pgrep -x "ollama" > /dev/null; then
    echo "Starting Ollama service..."
    ollama serve &
    sleep 5  # Give Ollama time to initialize
fi

# Start Docker services
echo "Starting Docker services..."
docker compose up -d

# Wait for web service
echo "Waiting for service to start..."
until curl -s http://localhost:8000 > /dev/null; do
    sleep 2
done

# Open browser based on OS
case "$(uname -s)" in
    Linux*)     xdg-open http://localhost:8000 ;;
    Darwin*)    open http://localhost:8000 ;;
    MINGW*)     start http://localhost:8000 ;;
    *)          echo "Please open http://localhost:8000 in your browser" ;;
esac

# Show logs
docker compose logs -f