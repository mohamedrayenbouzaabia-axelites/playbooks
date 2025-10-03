"""FastMCP server that wraps the Open-Meteo weather API."""

from __future__ import annotations

import json
from typing import Any, Dict, Union
from urllib.parse import urlencode
from urllib.request import urlopen
from fastmcp import FastMCP

API_URL = "https://api.open-meteo.com/v1/forecast"
DEFAULT_TIMEOUT = 10.0


def _coerce_to_bool(value: Union[bool, str]) -> bool:
    """Normalize truthy string representations to booleans."""
    if isinstance(value, bool):
        return value

    normalized = value.strip().lower()
    if normalized in {"true", "1", "yes", "y", "$true"}:
        return True
    if normalized in {"false", "0", "no", "n", "$false"}:
        return False

    raise ValueError(f"Unrecognized boolean value: {value}")

mcp = FastMCP("Weather MCP Server")


@mcp.tool
def get_current_weather(
    latitude: float,
    longitude: float,
    current_weather: Union[bool, str] = True,
    hourly: str | None = None,
) -> Dict[str, Any]:
    """Fetch current weather (and optionally hourly data) for a location."""
    current_weather_flag = _coerce_to_bool(current_weather)

    params: Dict[str, Any] = {
        "latitude": latitude,
        "longitude": longitude,
        "current_weather": str(current_weather_flag).lower(),
    }

    if hourly:
        params["hourly"] = hourly

    query = urlencode(params)
    url = f"{API_URL}?{query}"

    with urlopen(url, timeout=DEFAULT_TIMEOUT) as response:  # nosec B310
        if response.status != 200:
            raise RuntimeError(f"Weather API request failed with HTTP {response.status}")
        payload = response.read()

    data: Dict[str, Any] = json.loads(payload)

    if current_weather and "current_weather" in data:
        return data["current_weather"]

    return data


if __name__ == "__main__":
    mcp.run(transport="streamable-http")
