FROM python:3.11-alpine

WORKDIR /app

COPY server.py .

# Cloud Run uses PORT env var (default 8080)
ENV PORT=8080

EXPOSE 8080

CMD ["python", "server.py"]
