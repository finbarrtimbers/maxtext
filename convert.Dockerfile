FROM python:3.10.11
ENV PYTHONUNBUFFERED=1

RUN apt update && apt install -y sudo ripgrep fd-find bwm-ng zstd rsync

# Install gcloud sdk
WORKDIR /usr/local
RUN curl -O https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-cli-429.0.0-linux-x86_64.tar.gz
RUN tar -xzf google-cloud-cli-429.0.0-linux-x86_64.tar.gz && rm google-cloud-cli-429.0.0-linux-x86_64.tar.gz
RUN ./google-cloud-sdk/install.sh --quiet --path-update false
ENV PATH="/usr/local/google-cloud-sdk/bin:$PATH"

# Install poetry
WORKDIR /usr/local/poetry
RUN curl -sSL https://install.python-poetry.org | POETRY_VERSION=1.5.1 POETRY_HOME=/usr/local/poetry python3 -
# Always run poetry as root
RUN printf '#!/bin/bash\nsudo -E /usr/local/poetry/bin/poetry "$@"' > /usr/local/bin/poetry \
    && chmod +x /usr/local/bin/poetry

# Create a virtualenv for poetry install
RUN pip install virtualenv
RUN mkdir /venv
RUN virtualenv /venv
ENV VIRTUAL_ENV=/venv
ENV PATH="/venv/bin:$PATH"

RUN git config --global url."git@github.com:".insteadOf "https://github.com/"
RUN mkdir -p -m 0700 ~/.ssh && ssh-keyscan github.com >> ~/.ssh/known_hosts

WORKDIR /app

COPY requirements.txt .

RUN python -m pip install -r requirements.txt

RUN gcloud config set compute/zone us-central2-b

COPY . .
WORKDIR /app/MaxText