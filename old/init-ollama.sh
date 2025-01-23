#!/bin/bash
set -x  # Enable debug mode

# Start Ollama in the background
echo "Starting Ollama..."
ollama serve &
OLLAMA_PID=$!

# Function to check if model exists
check_model() {
    local model=$1
    curl -s http://localhost:11434/api/show -d "{\"name\":\"$model\"}" | grep -q "model"
    return $?
}

# Function to pull model
pull_model() {
    local model=$1
    if check_model "$model"; then
        echo "Model $model already exists"
    else
        echo "Pulling model: $model"
        curl -X POST http://localhost:11434/api/pull -d "{\"name\": \"$model\"}"
        echo "Finished pulling $model"
    fi
}

# Wait for Ollama to be ready
until curl -s http://localhost:11434/api/version > /dev/null; do
    echo "Waiting for Ollama to start... ($(date))"
    sleep 2
done

echo "Ollama is running and API is available"

# List all available models
echo "Available models before pulling:"
curl -s http://localhost:11434/api/tags

# Pull required models
pull_model "mxbai-embed-large"
pull_model "mistral"

echo "Available models after pulling:"
curl -s http://localhost:11434/api/tags

# Keep Ollama running
wait $OLLAMA_PID