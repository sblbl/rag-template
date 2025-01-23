#!/bin/bash

# Start the services
docker compose up -d

echo "Starting Ollama server..."
ollama serve &

echo "Waiting for Ollama server to be active..."
while [ "$(ollama list | grep 'NAME')" == "" ]; do
  sleep 1
done

echo "Ollama server is active."

# Function to check if the web service is ready
check_web_service() {
    curl -s http://localhost:8000 > /dev/null
    return $?
}

# Wait for the web service to be ready
echo "Waiting for the service to start..."
while ! check_web_service; do
    sleep 2
done

# Open the browser based on the operating system
case "$(uname -s)" in
    Linux*)     xdg-open http://localhost:8000 ;;
    Darwin*)    open http://localhost:8000 ;; # For macOS
    MINGW*)     start http://localhost:8000 ;; # For Windows Git Bash
    *)          echo "Please open http://localhost:8000 in your browser" ;;
esac

# Show the logs
docker compose logs -f