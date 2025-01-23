from fastapi import FastAPI, Request, Form
from fastapi.templating import Jinja2Templates
from fastapi.responses import HTMLResponse
from fastapi.responses import JSONResponse
from fastapi.staticfiles import StaticFiles
from fastapi.exceptions import RequestValidationError
from starlette.exceptions import HTTPException as StarletteHTTPException
import uvicorn
from query_data import query_rag
import logging

app = FastAPI()

# Create a templates directory and mount it
templates = Jinja2Templates(directory="templates")

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

@app.get("/", response_class=HTMLResponse)
async def home(request: Request):
	return templates.TemplateResponse(
		"index.html", 
		{"request": request, "response": None}
	)

@app.post("/query", response_class=HTMLResponse)
async def query(request: Request, query: str = Form(...)):
	try:
		response = query_rag(query)
		return JSONResponse({
			"response": response["text"],
			"sources": response["sources"],
			"query": query
		})
	except Exception as e:
		logger.error(f"Error querying RAG: {e}")
		response = {"text": "An error occurred while processing your request.", "sources": []}
		return templates.TemplateResponse(
			"index.html", 
			{"request": request, "response": response["text"], "sources": response["sources"], "query": query}
		)

@app.exception_handler(StarletteHTTPException)
async def http_exception_handler(request, exc):
    return JSONResponse({"detail": exc.detail}, status_code=exc.status_code)

@app.exception_handler(RequestValidationError)
async def validation_exception_handler(request, exc):
    return JSONResponse({"detail": exc.errors()}, status_code=400)

if __name__ == "__main__":
	uvicorn.run("app:app", host="0.0.0.0", port=8000, reload=True)

# on terminal: uvicorn app:app --host=0.0.0.0 --port=8000
# on browser: http://localhost:8000/