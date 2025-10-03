"""FastMCP server that proxies Newsdata.io news search."""

from __future__ import annotations

import json
import os
from typing import Any, Dict, List, Optional
from urllib.error import HTTPError
from urllib.parse import urlencode
from urllib.request import urlopen

from fastmcp import FastMCP

API_URL = "https://newsdata.io/api/1/news"
DEFAULT_TIMEOUT = 10.0
API_KEY_ENV = "NEWSDATA_API_KEY"

mcp = FastMCP("News MCP Server")


def _get_api_key() -> str:
    api_key = os.environ.get(API_KEY_ENV)
    if not api_key:
        raise RuntimeError(
            f"Newsdata API key missing; set the {API_KEY_ENV} environment variable."
        )
    return api_key


# Newsdata accepts only a fixed set of categories
VALID_CATEGORIES = {
    "top",
    "world",
    "nation",
    "business",
    "technology",
    "entertainment",
    "sports",
    "science",
    "health",
}

CATEGORY_ALIASES = {
    "general": "top",
}


@mcp.tool
def get_top_headlines(
    country: str,
    category: str = "general",
    language: str = "en",
    query: Optional[str] = None,
    page_size: int = 5,
) -> List[Dict[str, Any]]:
    """Return top headlines for a country/category using newsdata.io."""
    api_key = _get_api_key()

    normalized_country = country.lower() if country else None
    if normalized_country and len(normalized_country) != 2:
        # newsdata expects ISO-3166 alpha-2 codes; fall back to query only
        normalized_country = None

    normalized_category = category.lower() if category else None
    if normalized_category in CATEGORY_ALIASES:
        normalized_category = CATEGORY_ALIASES[normalized_category]
    if normalized_category and normalized_category not in VALID_CATEGORIES:
        normalized_category = None

    params: Dict[str, Any] = {
        "apikey": api_key,
        "language": language,
        "q": query,
    }

    if normalized_country:
        params["country"] = normalized_country
    if normalized_category:
        params["category"] = normalized_category

    query = urlencode({k: v for k, v in params.items() if v is not None})
    url = f"{API_URL}?{query}"

    try:
        with urlopen(url, timeout=DEFAULT_TIMEOUT) as response:  # nosec B310
            if response.status != 200:
                raise RuntimeError(
                    f"Newsdata API request failed with HTTP {response.status}"
                )
            payload = response.read()
    except HTTPError as exc:  # pragma: no cover - network error path
        details = exc.read().decode("utf-8", errors="ignore") if exc.fp else ""
        raise RuntimeError(
            f"Newsdata API request failed with HTTP {exc.code}: {details}"
        ) from exc

    data: Dict[str, Any] = json.loads(payload)

    articles: Optional[List[Dict[str, Any]]] = data.get("results")
    if not articles:
        return []

    max_items = max(1, min(page_size, 10))

    simplified: List[Dict[str, Any]] = []
    for article in articles[:max_items]:
        simplified.append(
            {
                "title": article.get("title"),
                "description": article.get("description"),
                "url": article.get("link"),
                "source": article.get("source_name") or article.get("source_id"),
            }
        )

    return simplified


if __name__ == "__main__":
    mcp.run(transport="streamable-http")
