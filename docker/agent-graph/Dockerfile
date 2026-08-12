FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

COPY pyproject.toml README.md langgraph.json ./
COPY src ./src
RUN pip install --no-cache-dir ".[llm]" "langgraph-cli[inmem]>=0.4,<1.0" && touch .env

EXPOSE 2024

CMD ["langgraph", "dev", "--host", "0.0.0.0", "--port", "2024", "--no-browser"]
