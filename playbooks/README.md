# Daily Briefing Playbook

1. Start the weather MCP bridge:
   ```bash
   fastmcp run playbooks/weather_mcp.py -t streamable-http --port 8888
   ```
2. Start the news MCP bridge:
   ```bash
   fastmcp run playbooks/news_mcp.py -t streamable-http --port 8889
   ```
3. In a separate terminal (the one where you run the Playbooks CLI), set the API key so the local wrapper can authenticate:
   ```bash
   export NEWSDATA_API_KEY=your_key
   ```
4. Compile or run `playbooks/daily_briefing.pb` through the Playbooks CLI/agent runtime.

The assistant will remember the city provided by the user, call both MCP agents, and blend the results into a reasoning-focused daily briefing.
