FROM ubuntu:22.04

RUN apt-get update && apt-get install -y \
    ttyd \
    bash \
    curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY cloudmaster.sh /app/cloudmaster.sh
RUN chmod +x /app/cloudmaster.sh

EXPOSE 7681

CMD ["ttyd", "--port", "7681", "--interface", "0.0.0.0", "/app/cloudmaster.sh"]
