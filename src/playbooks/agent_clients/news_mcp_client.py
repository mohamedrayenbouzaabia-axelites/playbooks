"""Utility helpers for calling the News MCP server with secret injection."""

from __future__ import annotations

import os
from typing import Any, Dict, List, Optional

from fastmcp import Client
from fastmcp.client.transports import StreamableHttpTransport
from playbooks.debug_logger import debug as debug_log

NEWS_MCP_URL_ENV = "NEWS_MCP_URL"
DEFAULT_NEWS_MCP_URL = "http://127.0.0.1:8889/mcp"
API_KEY_ENV = "NEWSDATA_API_KEY"


def _get_server_url() -> str:
    return os.environ.get(NEWS_MCP_URL_ENV, DEFAULT_NEWS_MCP_URL)


def _get_api_key() -> str:
    api_key = os.environ.get(API_KEY_ENV)
    if not api_key:
        raise RuntimeError(
            f"Newsdata API key missing; set the {API_KEY_ENV} environment variable."
        )
    return api_key


async def fetch_news_headlines(
    *,
    country_code: str,
    category: str = "general",
    language: str = "en",
    query: Optional[str] = None,
    page_size: int = 5,
) -> List[Dict[str, Any]]:
    """Call the News MCP tool and return simplified headlines."""

    api_key = _get_api_key()
    server_url = _get_server_url()

    arguments: Dict[str, Any] = {
        "country": country_code,
        "category": category,
        "language": language,
        "query": query,
        "page_size": page_size,
        "api_key": api_key,
    }

    transport = StreamableHttpTransport(server_url)
    async with Client(transport) as client:
        masked_arguments = {**arguments, "api_key": "***"}
        debug_log("News MCP call", arguments=masked_arguments)
        result = await client.call_tool("get_top_headlines", arguments)
        debug_log(
            "News MCP response",
            structured=bool(result.structured_content),
            has_data=bool(result.data),
            content_count=len(result.content),
        )

    if result.structured_content:
        structured = result.structured_content
        if isinstance(structured, dict) and "result" in structured:
            structured = structured["result"]
        return structured  # type: ignore[return-value]

    if result.data is not None:
        return result.data  # type: ignore[return-value]

    # Fallback to textual content aggregation
    headlines: List[Dict[str, Any]] = []
    for block in result.content:
        text = getattr(block, "text", None)
        if text:
            headlines.append({"title": text})
    debug_log("News MCP fallback content", headlines=len(headlines))
    return headlines
