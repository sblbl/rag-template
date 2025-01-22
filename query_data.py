import argparse
from langchain_chroma import Chroma
from langchain_core.prompts import ChatPromptTemplate
from langchain_ollama import OllamaLLM

from get_embedding_function import get_embedding_function

CHROMA_PATH = "chroma"

PROMPT_TEMPLATE = """
Answer the question based only on the following context:

{context}

---

Answer the question based on the above context: {question}
"""


def main():
	# Create CLI.
	parser = argparse.ArgumentParser()
	parser.add_argument("query_text", type=str, help="The query text.")
	args = parser.parse_args()
	query_text = args.query_text
	query_rag(query_text)


def query_rag(query_text: str):
	# Prepare the DB.
	embedding_function = get_embedding_function()
	db = Chroma(persist_directory=CHROMA_PATH, embedding_function=embedding_function)

	# Search the DB.
	results = db.similarity_search_with_score(query_text, k=5)

	context_text = "\n\n---\n\n".join([doc.page_content for doc, _score in results])
	prompt_template = ChatPromptTemplate.from_template(PROMPT_TEMPLATE)
	prompt = prompt_template.format(context=context_text, question=query_text)
	# print(prompt)

	model = OllamaLLM(model="mistral")
	response_text = model.invoke(prompt)
	print("\nAI Response:")
	print(response_text)
	print("\n\n\n")
	print("\nSources Used:")
	for i, (doc, score) in enumerate(results, 1):
		print(f"\nSource {i}:")
		print(f"- ID: {doc.metadata.get('id', 'Unknown')}")
		print(f"- Similarity Score: {score:.2f}")
		print(f"- Content:")
		print("---")
		print(doc.page_content)
		print("---")
		print("\n")
	return {
		"text": response_text,
		"sources": [{"id": doc.metadata.get("id", None), "page_content": doc.page_content, "score": score} for doc, score in results]
	}


if __name__ == "__main__":
	main()