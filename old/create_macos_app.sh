#!/bin/bash

# Set the app name
APP_NAME="RAG Assistant"
BUNDLE_NAME="$APP_NAME.app"

# Create the .app bundle structure
mkdir -p "$BUNDLE_NAME/Contents/MacOS"
mkdir -p "$BUNDLE_NAME/Contents/Resources"

# Copy all necessary files into the Resources directory
echo "Copying application files..."
cp -R docker-compose.yml Dockerfile requirements.txt populate_database.py query_data.py app.py get_embedding_function.py "$BUNDLE_NAME/Contents/Resources/"
mkdir -p "$BUNDLE_NAME/Contents/Resources/data"
mkdir -p "$BUNDLE_NAME/Contents/Resources/chroma"

# Create the Info.plist file
cat > "$BUNDLE_NAME/Contents/Info.plist" << EOL
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>run.sh</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>com.example.ragassistant</string>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>LSMinimumSystemVersion</key>
    <string>10.10</string>
    <key>LSBackgroundOnly</key>
    <string>0</string>
</dict>
</plist>
EOL

# Create the executable script
cat > "$BUNDLE_NAME/Contents/MacOS/run.sh" << 'EOL'
#!/bin/bash

# Change to the Resources directory where our files are located
cd "$(dirname "${BASH_SOURCE[0]}")/../Resources" || exit 1

# Function to display a notification
show_notification() {
    osascript -e "display notification \"$1\" with title \"RAG Assistant\""
}

# Function to show error and exit
show_error() {
    show_notification "Error: $1"
    echo "Error: $1"
    exit 1
}

# Function to check if Docker is running
check_docker() {
    # First, check if Docker is installed
    if ! command -v docker &> /dev/null; then
        show_error "Docker is not installed. Please install Docker Desktop first."
    fi

    # Then check if Docker is running
    if ! docker info &> /dev/null; then
        show_notification "Starting Docker..."
        open -a "Docker"
        
        # Wait for Docker to start (timeout after 60 seconds)
        local timeout=60
        while ! docker info &> /dev/null && [ $timeout -gt 0 ]; do
            sleep 1
            ((timeout--))
        done
        
        if [ $timeout -eq 0 ]; then
            show_error "Docker failed to start. Please start Docker Desktop manually."
        fi
    fi
}

# Function to check if Ollama is running
check_ollama() {
    # Check if Ollama container is running
    if ! curl -s http://localhost:11434/api/tags &> /dev/null; then
        show_notification "Starting Ollama..."
        if ! docker ps | grep -q ollama; then
            docker compose up -d ollama
            sleep 5  # Give Ollama time to start
        fi
    fi
}

# Function to check and pull required Ollama models
check_models() {
    show_notification "Checking required models..."
    
    # Wait for Ollama to be responsive
    local timeout=30
    while ! curl -s http://localhost:11434/api/tags &> /dev/null && [ $timeout -gt 0 ]; do
        sleep 1
        ((timeout--))
    done
    
    if [ $timeout -eq 0 ]; then
        show_error "Ollama is not responding. Please check if it's running properly."
    fi
    
    # Check and pull models
    if ! curl -s http://localhost:11434/api/tags | grep -q "mxbai-embed-large"; then
        show_notification "Pulling mxbai-embed-large model..."
        curl -X POST http://localhost:11434/api/pull -d '{"name": "mxbai-embed-large"}'
    fi
    
    if ! curl -s http://localhost:11434/api/tags | grep -q "mistral"; then
        show_notification "Pulling mistral model..."
        curl -X POST http://localhost:11434/api/pull -d '{"name": "mistral"}'
    fi
}

# Main execution starts here
show_notification "Starting RAG Assistant..."

# Check and start required services
check_docker
check_ollama
check_models

# Start the main application
show_notification "Starting application services..."
docker compose up -d

# Wait for the web service (timeout after 30 seconds)
timeout=30
while ! curl -s http://localhost:8000 &> /dev/null && [ $timeout -gt 0 ]; do
    sleep 1
    ((timeout--))
done

if [ $timeout -eq 0 ]; then
    show_error "Web service failed to start. Please check the logs."
fi

# Open browser
open http://localhost:8000
show_notification "RAG Assistant is ready!"

# Cleanup function
cleanup() {
    show_notification "Shutting down services..."
    docker compose down
    exit 0
}

# Set up trap for cleanup
trap cleanup EXIT INT TERM

# Keep the application running and monitor the containers
while true; do
    if ! docker ps | grep -q "rag-assistant"; then
        show_error "Application container stopped unexpectedly"
    fi
    sleep 5
done
EOL

# Make the script executable
chmod +x "$BUNDLE_NAME/Contents/MacOS/run.sh"

echo "macOS app bundle created successfully!"