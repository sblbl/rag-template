import os
from langchain_ollama import OllamaEmbeddings

def get_embedding_function():
    base_url = os.getenv("OLLAMA_BASE_URL", "http://localhost:11434")
    print(f"Connecting to Ollama at: {base_url}")  # Debug log
    embeddings = OllamaEmbeddings(
        model="mxbai-embed-large",
        base_url=base_url
    )
    return embeddings