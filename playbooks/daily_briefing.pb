# Weather MCP Agent
metadata:
  remote:
    type: mcp
    url: http://127.0.0.1:8888/mcp
    transport: streamable-http
---
Proxies the Open-Meteo API for current conditions. Start with `fastmcp run playbooks/weather_mcp.py -t streamable-http --port 8888`.

```public.json
[]

```

# News MCP Agent
metadata:
  remote:
    type: mcp
    url: http://127.0.0.1:8889/mcp
    transport: streamable-http
---
Proxies Newsdata.io search. Start with `NEWSDATA_API_KEY=... fastmcp run playbooks/news_mcp.py -t streamable-http --port 8889`.

```public.json
[]

```

# Daily Briefing Assistant
startup_mode: standby
## Main
### Trigger
- When user says "Give me my daily briefing"

### Steps
- Say "Sure! Which city should I prepare it for?" and remember the response as $city.
- Determine $latitude, $longitude, and $country for $city. Ask follow-up questions if unsure, and remember the resolved values.
- Infer a two-letter $country_code (ISO 3166-1 alpha-2) that best matches $city and $country; verify the guess with the user if there is ambiguity.
- $weather = Weather MCP Agent's get_current_weather with:
    latitude=$latitude
    longitude=$longitude
    current_weather=true
- $news = News MCP Agent's get_top_headlines with:
    country=$country_code
    category=general
    query=$country
    page_size=5
- Compose a final message:
    - If $weather.temperature < 10, mention "Bundle up, it's cold." If $weather.temperature > 25, mention "It's hot, stay hydrated."
    - List the top two headlines from $news (skip if missing).
    - Reply: "Good morning! Here's your daily briefing for $city:" followed by weather summary and the headline list.

```public.json
[]

```
