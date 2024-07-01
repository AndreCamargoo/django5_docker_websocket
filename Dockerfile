# syntax=docker/dockerfile:1
FROM python:3

# Essa variável de ambiente é usada para controlar se o Python deve
# gravar arquivos de bytecode (.pyc) no disco. 1 = Não, 0 = Sim
ENV PYTHONDONTWRITEBYTECODE=1

# Define que a saída do Python será exibida imediatamente no console ou em
# outros dispositivos de saída, sem ser armazenada em buffer.
# Em resumo, você verá os outputs do Python em tempo real.
ENV PYTHONUNBUFFERED=1

# Entra na pasta djangoapp no container (trabalhar com essa pasta)
WORKDIR /code

COPY requirements.txt /code/

RUN python -m venv /venv && \
    /venv/bin/pip install --upgrade pip && \
    /venv/bin/pip install -r /code/requirements.txt && \
    adduser --disabled-password --no-create-home duser && \
    mkdir -p /data/web/static && \
    mkdir -p /data/web/staticfiles && \
    mkdir -p /data/web/media && \
    chown -R duser:duser /venv && \
    chown -R duser:duser /data/web/static && \
    chown -R duser:duser /data/web/staticfiles && \
    chown -R duser:duser /data/web/media && \
    chmod -R 755 /data/web/static && \
    chmod -R 755 /data/web/staticfiles && \
    chmod -R 755 /data/web/media && \
    pip install -r requirements.txt

# Muda o usuário para duser
USER duser

COPY . /code/
