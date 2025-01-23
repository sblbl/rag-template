import argparse
from langchain_chroma import Chroma
from langchain_core.prompts import ChatPromptTemplate
from langchain_ollama import OllamaLLM
import os
import time

from get_embedding_function import get_embedding_function

CHROMA_PATH = "chroma"

PROMPT_TEMPLATE = """
Answer the question based only on the following context:

{context}

---

Answer the question based on the above context: {question}
"""

def wait_for_ollama(base_url, max_retries=5):
    for i in range(max_retries):
        try:
            model = OllamaLLM(model="mistral", base_url=base_url)
            # Try a simple query to verify connection
            model.invoke("test")
            print(f"Successfully connected to Ollama at {base_url}")
            return True
        except Exception as e:
            print(f"Attempt {i+1}/{max_retries} to connect to Ollama failed: {str(e)}")
            if i < max_retries - 1:
                time.sleep(5)
    return False

def query_rag(query_text: str):
    try:
        # Get Ollama base URL
        ollama_base_url = os.getenv("OLLAMA_BASE_URL", "http://localhost:11434")
        print(f"Using Ollama base URL: {ollama_base_url}")

        # Wait for Ollama to be ready
        if not wait_for_ollama(ollama_base_url):
            raise Exception("Failed to connect to Ollama after multiple attempts")

        # Prepare the DB
        print("Initializing embedding function...")
        embedding_function = get_embedding_function()
        
        print("Connecting to Chroma database...")
        db = Chroma(persist_directory=CHROMA_PATH, embedding_function=embedding_function)

        # Search the DB
        print("Performing similarity search...")
        results = db.similarity_search_with_score(query_text, k=5)

        context_text = "\n\n---\n\n".join([doc.page_content for doc, _score in results])
        prompt_template = ChatPromptTemplate.from_template(PROMPT_TEMPLATE)
        prompt = prompt_template.format(context=context_text, question=query_text)

        print("Initializing LLM...")
        model = OllamaLLM(model="mistral", base_url=ollama_base_url)
        
        print("Generating response...")
        response_text = model.invoke(prompt)
        
        return {
            "text": response_text,
            "sources": [{"id": doc.metadata.get("id", None), "page_content": doc.page_content, "score": score} for doc, score in results]
        }
    except Exception as e:
        error_message = f"Error processing query: {str(e)}"
        print(error_message)
        return {
            "text": f"An error occurred: {error_message}",
            "sources": []
        }