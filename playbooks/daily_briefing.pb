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
- $country_code = GetCountryCode(country=$country)
- $weather = Weather MCP Agent's get_current_weather with:
    latitude=$latitude
    longitude=$longitude
    current_weather=true
- $news = FetchNewsHeadlines with:
    country_code=$country_code
    category=general
    query=$city
    page_size=5
- $formatted_headlines = FormatHeadlines(headlines=$news)
- $briefing = BuildBriefing(city=$city, weather=$weather, formatted_headlines=$formatted_headlines)
- Say $briefing

```public.json
[]

```

```python
from playbooks.agent_clients.news_mcp_client import fetch_news_headlines
from playbooks.debug_logger import debug as debug_log


@playbook
async def FetchNewsHeadlines(
  country_code: str,
  category: str = "general",
  query: str | None = None,
  page_size: int = 5,
):
  return await fetch_news_headlines(
    country_code=country_code,
    category=category,
    query=query,
    page_size=page_size,
  )


@playbook
async def FormatHeadlines(headlines: list) -> list[str]:
  debug_log("Formatting headlines", count=len(headlines))
  formatted = []
  for item in headlines[:2]:
    title = item.get("title") or "(untitled)"
    source = item.get("source")
    formatted.append(f"{title} — {source}" if source else title)
  return formatted


@playbook
async def BuildBriefing(city: str, weather: dict, formatted_headlines: list[str]) -> str:
  lines: list[str] = []
  city_clean = city.title()
  lines.append(f"Good morning! Here's your daily briefing for {city_clean}:")

  temperature = weather.get("temperature")
  windspeed = weather.get("windspeed")

  if temperature is not None and windspeed is not None:
    lines.append(f"Weather: {temperature} °C with {windspeed} km/h wind.")
  elif temperature is not None:
    lines.append(f"Weather: {temperature} °C.")
  elif windspeed is not None:
    lines.append(f"Wind speed: {windspeed} km/h.")

  try:
    temp_value = float(temperature) if temperature is not None else None
  except (TypeError, ValueError):
    temp_value = None

  if temp_value is not None:
    if temp_value < 10:
      lines.append("Bundle up, it's cold.")
    elif temp_value > 25:
      lines.append("It's hot, stay hydrated.")

  if formatted_headlines:
    lines.append(f"Top {len(formatted_headlines)} headlines:")
    for idx, headline in enumerate(formatted_headlines, start=1):
      lines.append(f"{idx}. {headline}")
  else:
    lines.append("No reliable headlines were available.")

  briefing = "\n".join(lines)
  debug_log("Built briefing", briefing=briefing)
  return briefing


COUNTRY_CODE_MAP = {
  "afghanistan": "af",
  "albania": "al",
  "algeria": "dz",
  "andorra": "ad",
  "angola": "ao",
  "antigua and barbuda": "ag",
  "argentina": "ar",
  "armenia": "am",
  "australia": "au",
  "austria": "at",
  "azerbaijan": "az",
  "bahamas": "bs",
  "bahrain": "bh",
  "bangladesh": "bd",
  "barbados": "bb",
  "belarus": "by",
  "belgium": "be",
  "belize": "bz",
  "benin": "bj",
  "bhutan": "bt",
  "bolivia": "bo",
  "bosnia and herzegovina": "ba",
  "botswana": "bw",
  "brazil": "br",
  "brunei": "bn",
  "bulgaria": "bg",
  "burkina faso": "bf",
  "burundi": "bi",
  "cambodia": "kh",
  "cameroon": "cm",
  "canada": "ca",
  "cape verde": "cv",
  "central african republic": "cf",
  "chad": "td",
  "chile": "cl",
  "china": "cn",
  "colombia": "co",
  "comoros": "km",
  "congo": "cg",
  "democratic republic of the congo": "cd",
  "costa rica": "cr",
  "cote d'ivoire": "ci",
  "ivory coast": "ci",
  "croatia": "hr",
  "cuba": "cu",
  "cyprus": "cy",
  "czech republic": "cz",
  "czechia": "cz",
  "denmark": "dk",
  "djibouti": "dj",
  "dominica": "dm",
  "dominican republic": "do",
  "ecuador": "ec",
  "egypt": "eg",
  "el salvador": "sv",
  "equatorial guinea": "gq",
  "eritrea": "er",
  "estonia": "ee",
  "eswatini": "sz",
  "ethiopia": "et",
  "fiji": "fj",
  "finland": "fi",
  "france": "fr",
  "gabon": "ga",
  "gambia": "gm",
  "georgia": "ge",
  "germany": "de",
  "ghana": "gh",
  "greece": "gr",
  "grenada": "gd",
  "guatemala": "gt",
  "guinea": "gn",
  "guinea-bissau": "gw",
  "guyana": "gy",
  "haiti": "ht",
  "honduras": "hn",
  "hungary": "hu",
  "iceland": "is",
  "india": "in",
  "indonesia": "id",
  "iran": "ir",
  "iraq": "iq",
  "ireland": "ie",
  "israel": "il",
  "italy": "it",
  "jamaica": "jm",
  "japan": "jp",
  "jordan": "jo",
  "kazakhstan": "kz",
  "kenya": "ke",
  "kiribati": "ki",
  "kuwait": "kw",
  "kyrgyzstan": "kg",
  "laos": "la",
  "latvia": "lv",
  "lebanon": "lb",
  "lesotho": "ls",
  "liberia": "lr",
  "libya": "ly",
  "liechtenstein": "li",
  "lithuania": "lt",
  "luxembourg": "lu",
  "madagascar": "mg",
  "malawi": "mw",
  "malaysia": "my",
  "maldives": "mv",
  "mali": "ml",
  "malta": "mt",
  "marshall islands": "mh",
  "mauritania": "mr",
  "mauritius": "mu",
  "mexico": "mx",
  "micronesia": "fm",
  "moldova": "md",
  "monaco": "mc",
  "mongolia": "mn",
  "montenegro": "me",
  "morocco": "ma",
  "mozambique": "mz",
  "myanmar": "mm",
  "namibia": "na",
  "nauru": "nr",
  "nepal": "np",
  "netherlands": "nl",
  "new zealand": "nz",
  "nicaragua": "ni",
  "niger": "ne",
  "nigeria": "ng",
  "north korea": "kp",
  "north macedonia": "mk",
  "norway": "no",
  "oman": "om",
  "pakistan": "pk",
  "palau": "pw",
  "panama": "pa",
  "papua new guinea": "pg",
  "paraguay": "py",
  "peru": "pe",
  "philippines": "ph",
  "poland": "pl",
  "portugal": "pt",
  "qatar": "qa",
  "romania": "ro",
  "russia": "ru",
  "rwanda": "rw",
  "saint kitts and nevis": "kn",
  "saint lucia": "lc",
  "samoa": "ws",
  "san marino": "sm",
  "sao tome and principe": "st",
  "saudi arabia": "sa",
  "senegal": "sn",
  "serbia": "rs",
  "seychelles": "sc",
  "sierra leone": "sl",
  "singapore": "sg",
  "slovakia": "sk",
  "slovenia": "si",
  "solomon islands": "sb",
  "somalia": "so",
  "south africa": "za",
  "south korea": "kr",
  "south sudan": "ss",
  "spain": "es",
  "sri lanka": "lk",
  "sudan": "sd",
  "suriname": "sr",
  "sweden": "se",
  "switzerland": "ch",
  "syria": "sy",
  "taiwan": "tw",
  "tajikistan": "tj",
  "tanzania": "tz",
  "thailand": "th",
  "timor-leste": "tl",
  "togo": "tg",
  "tonga": "to",
  "trinidad and tobago": "tt",
  "tunisia": "tn",
  "turkey": "tr",
  "turkmenistan": "tm",
  "tuvalu": "tv",
  "uganda": "ug",
  "ukraine": "ua",
  "united arab emirates": "ae",
  "united kingdom": "gb",
  "uk": "gb",
  "united states": "us",
  "usa": "us",
  "uruguay": "uy",
  "uzbekistan": "uz",
  "vanuatu": "vu",
  "vatican city": "va",
  "venezuela": "ve",
  "vietnam": "vn",
  "yemen": "ye",
  "zambia": "zm",
  "zimbabwe": "zw",
}


@playbook
async def GetCountryCode(country: str) -> str:
  if not country:
    return ""
  normalized = country.strip().lower()
  # Handle cases like "Tunisia Ariana"
  parts = normalized.split()
  for size in range(len(parts), 0, -1):
    candidate = " ".join(parts[-size:])
    if candidate in COUNTRY_CODE_MAP:
      return COUNTRY_CODE_MAP[candidate]

  # Direct lookup
  if normalized in COUNTRY_CODE_MAP:
    return COUNTRY_CODE_MAP[normalized]

  # Already a two-letter code
  if len(normalized) == 2 and normalized.isalpha():
    return normalized.lower()

  return ""
```
