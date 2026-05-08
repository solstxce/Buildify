import os
from typing import Any

import requests
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel

app = FastAPI(title="Buildify AI Server Shim")

LLAMA_BASE_URL = os.getenv("LLAMA_BASE_URL", "http://127.0.0.1:8080")


class CompletionRequest(BaseModel):
    prompt: str
    n_predict: int = 100
    temperature: float = 0.7


class ChatMessage(BaseModel):
    role: str
    content: str


class ChatRequest(BaseModel):
    messages: list[ChatMessage]
    n_predict: int = 100
    temperature: float = 0.7


@app.get("/health")
def health() -> dict[str, Any]:
    return {
        "status": "ok",
        "llama_base_url": LLAMA_BASE_URL,
    }


@app.post("/completion")
def completion(body: CompletionRequest) -> dict[str, Any]:
    return _post_llama(
        "/completion",
        {
            "prompt": body.prompt,
            "n_predict": body.n_predict,
            "temperature": body.temperature,
        },
    )


@app.post("/chat")
def chat(body: ChatRequest) -> dict[str, Any]:
    prompt = "\n".join(f"{m.role}: {m.content}" for m in body.messages)
    return _post_llama(
        "/completion",
        {
            "prompt": prompt,
            "n_predict": body.n_predict,
            "temperature": body.temperature,
        },
    )


@app.get("/generate")
def generate(prompt: str) -> dict[str, Any]:
    return completion(CompletionRequest(prompt=prompt, n_predict=50))


def _post_llama(path: str, payload: dict[str, Any]) -> dict[str, Any]:
    try:
        response = requests.post(
            f"{LLAMA_BASE_URL}{path}",
            json=payload,
            timeout=120,
        )
        response.raise_for_status()
    except requests.RequestException as exc:
        raise HTTPException(
            status_code=502,
            detail=f"llama server unavailable: {exc}",
        ) from exc
    return response.json()
