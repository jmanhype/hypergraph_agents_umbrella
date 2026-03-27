from fastapi import FastAPI, Request, Response
from fastapi.responses import StreamingResponse, JSONResponse
from typing import AsyncGenerator, Dict, Any
import asyncio
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(title="Minimal Python A2A Agent")

AGENT_CARD: Dict[str, Any] = {
    "id": "pyagent1",
    "name": "Python Agent",
    "version": "0.1.0",
    "description": "Minimal Python A2A agent",
    "capabilities": ["task_request", "agent_discovery"],
    "endpoints": {"a2a": "/api/a2a", "agent_card": "/api/agent_card"},
    "authentication": None
}

@app.get("/api/agent_card")
def get_agent_card() -> Dict[str, Any]:
    """Return this agent's card for discovery."""
    return AGENT_CARD

@app.post("/api/agent_card")
def register_agent_card(card: Dict[str, Any]) -> Dict[str, Any]:
    """Accept and echo agent card registration (stub for demo)."""
    return {"status": "ok", "card": card}

async def stream_task_progress() -> AsyncGenerator[bytes, None]:
    """Simulate streaming task progress events."""
    for i in range(5):
        yield (f'{ {"type": "task_progress", "progress": i*20} }\n').encode()
        await asyncio.sleep(0.5)
    yield b'{"type": "result", "payload": {"result": "done"}}\n'

@app.post("/api/a2a")
async def a2a_endpoint(request: Request) -> Response:
    """Accept A2A messages and stream responses if requested. Handles task_request, task_chunk, agent_event, and errors."""
    try:
        body = await request.json()
    except Exception as e:
        logger.error(f"Failed to parse JSON: {e}")
        return JSONResponse(
            {"status": "error", "error": "Invalid JSON payload"},
            status_code=400
        )

    # Strict error check FIRST
    if "type" not in body or not isinstance(body.get("type"), str):
        logger.error(f"Missing or invalid 'type' field in message: {body}")
        return JSONResponse(
            {"status": "error", "error": "Missing or invalid 'type' field"},
            status_code=400
        )

    msg_type: str = body["type"]
    payload: Dict[str, Any] = body.get("payload", {})

    # Streaming for task_request
    if msg_type == "task_request" and payload.get("stream", False):
        return StreamingResponse(stream_task_progress(), media_type="application/json")

    # Always stream for task_chunk (even if no stream param)
    if msg_type == "task_chunk":
        async def chunk_stream() -> AsyncGenerator[bytes, None]:
            for i in range(3):
                chunk: Dict[str, Any] = {"type": "task_chunk", "chunk": f"partial_{i}"}
                yield (f"{chunk}\n").encode()
                await asyncio.sleep(0.3)
            result: Dict[str, Any] = {"type": "result", "payload": {"result": "final from chunk"}}
            yield (f"{result}\n").encode()
        return StreamingResponse(chunk_stream(), media_type="application/json")

    if msg_type == "agent_event":
        # Log and acknowledge
        logger.info(f"[agent_event] {payload}")
        return JSONResponse({"status": "ok", "type": "agent_event", "event": payload})

    # Default: echo
    return JSONResponse({"status": "ok", "type": msg_type, "echo": body})
