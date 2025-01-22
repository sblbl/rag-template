from fastapi import FastAPI, Request, Form
from fastapi.templating import Jinja2Templates
from fastapi.responses import HTMLResponse
from fastapi.staticfiles import StaticFiles
import uvicorn
from query_data import query_rag

app = FastAPI()

# Create a templates directory and mount it
templates = Jinja2Templates(directory="templates")

@app.get("/", response_class=HTMLResponse)
async def home(request: Request):
	return templates.TemplateResponse(
		"index.html", 
		{"request": request, "response": None}
	)

@app.post("/query", response_class=HTMLResponse)
async def query(request: Request, query: str = Form(...)):
	response = query_rag(query)
	return templates.TemplateResponse(
		"index.html", 
		{"request": request, "response": response["text"], "sources": response["sources"], "query": query}
	)

if __name__ == "__main__":
	uvicorn.run("app:app", host="0.0.0.0", port=8000, reload=True)