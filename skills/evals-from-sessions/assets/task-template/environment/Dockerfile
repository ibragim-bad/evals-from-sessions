FROM python:3.12-slim
# Pin the base image tag. Install every tool the agent and verifier need here;
# do not pin exact apt versions (they disappear from mirrors).
RUN apt-get update && apt-get install -y --no-install-recommends git \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /app
# private: repo/ is `git archive <parent-commit>`; shareable: a new starter repo.
COPY repo/ /app/
# One fresh commit: no history, tags, remotes, hooks or episode messages.
RUN git init -q && git add -A \
    && git -c user.name=task -c user.email=task@example.invalid commit -qm init
