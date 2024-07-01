# 👋 Hello, this is a django5 docker repository with Redis.

## Let's compile a simple chat using websockets.

### 1. You can simply clone the project.

```bash=
git clone git@github.com:AndreCamargoo/django5_docker_websocket.git
```

### After cloning, let's run the commands.

~~~bash
docker compose up --build -d
~~~

### If you have made any modifications to the Dockerfile and docker-compose files, use this command.

~~~bash
docker compose up --build --force-recreate -d
~~~

### Project URL when container is active:

```
http://localhost:8000/
http://127.0.0.1:8000/
```

### ⚠️ If you have any permission error to create <b>Data</b> folder, run commands.

~~~bash
sudo su
~~~

~~~bash
docker compose up --build --force-recreate -d
~~~

## Creating the application step by step:

### 1. Let's create the project folder.

~~~bash
mkdir chat && cd chat
~~~

### 2. Create the Dockerfile.

~~~bash
nano Dockerfile
~~~

<p>Copy and paste the content into the Dockerfile.</p>

```
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
```

### 3. Create the docker-compose.

~~~bash
nano docker-compose.yml
~~~

<p>Copy and paste the content into the docker-compose.yml.</p>

```
version: '3'
services:
  db:
    container_name: postgres
    image: postgres
    volumes:
      - ./data/db:/var/lib/postgresql/data
    environment:
      - POSTGRES_DB=postgres
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=postgres

  redis:
    container_name: redis
    image: redis:alpine
    restart: always
    ports:
      - '6379:6379'
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 1s
      timeout: 3s
      retries: 5
    volumes:
      - ./data/redis/data:/data

  web:
    build: .
    command: daphne -b 0.0.0.0 -p 8000 realtime.asgi:application
    volumes:
      - .:/code
    ports:
      - "8000:8000"
    environment:
      - POSTGRES_NAME=postgres
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=postgres
    depends_on:
      - db
      - redis
```
### 4. Create a virtual environment.

~~~bash
python3 -m venv venv
~~~

### 5. Activate the virtual environment

#### Windows
~~~bash
venv/Scripts/activate
~~~

#### Linux

~~~bash
source venv/bin/activate
~~~

### 6. Install python dependencies

~~~bash
pip install django django-bootstrap4 channels-redis psycopg2-binary -U 'channels[daphne]'
~~~

### 7. Publishing pip requirements dependencies to be used by Dockerfile.

~~~bash
pip freeze > requirements.txt
~~~

### 8. Creating the Django project.
~~~bash
django-admin startproject realtime .
~~~

### 9. Creating the Django APP.
~~~bash
django-admin startapp chat
~~~

### 10. Edit the realtime/settings.py file
~~~bash
nano realtime/settings.py
~~~

<p>Edit the lines and add what you don't have</p>

```
import os

ALLOWED_HOSTS = ['*']

INSTALLED_APPS = [
    'bootstrap4',
    'daphne',
    'chat',
    '...'
]

TEMPLATES = [
    {
        '...',
        'DIRS': ['templates'],
        '...,        
    },
]

LANGUAGE_CODE = 'pt-br'

TIME_ZONE = 'America/Sao_Paulo'

STATIC_URL = 'static/'
MEDIA_URL = 'media/'

STATIC_ROOT = os.path.join(BASE_DIR, 'staticfiles')
MEDIA_ROOT = os.path.join(BASE_DIR, 'media')

DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'

#Configuração do Channels porque a wsgi não suporta
ASGI_APPLICATION = 'realtime.routing.application'

CHANNEL_LAYERS = {
    'default': {
        'BACKEND': 'channels_redis.core.RedisChannelLayer',
        'CONFIG': {
            'hosts': [('redis', 6379)],
        },
    },
}
```

### 11. Edit the realtime/asgi.py file

~~~bash
nano realtime/asgi.py
~~~

<p>Edit and save</p>

```
import os
from django.core.asgi import get_asgi_application
from channels.routing import ProtocolTypeRouter, URLRouter
from channels.auth import AuthMiddlewareStack
from chat.routing import websocket_urlpatterns
 
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'realtime.settings')
 
# Regular Django ASGI application
django_asgi_application = get_asgi_application()
 
# Django Channels WebSocket application
application = ProtocolTypeRouter(
    {
        "http": django_asgi_application,
        "websocket": AuthMiddlewareStack(
            URLRouter(
                websocket_urlpatterns
            )
        ),
    }
)
```

### 12. Create file realtime/routing.py

~~~bash
nano realtime/routing.py
~~~

<p>Edit and save</p>

```
# realtime/routing.py

from channels.routing import ProtocolTypeRouter, URLRouter
from channels.auth import AuthMiddlewareStack
from django.core.asgi import get_asgi_application

import chat.routing

application = ProtocolTypeRouter({
    'http': get_asgi_application(),
    'websocket': AuthMiddlewareStack(
        URLRouter(
            chat.routing.websocket_urlpatterns
        )
    ),
})
```

### 13. Edit file realtime/urls.py

~~~bash
nano realtime/urls.py
~~~

<p>Edit and save</p>

```
from django.contrib import admin
from django.urls import path, include

urlpatterns = [
    path('admin/', admin.site.urls),
    path('', include('chat.urls')),
]
```

### 14. Create folder chat/templates

~~~bash
mkdir chat/templates
~~~

### 15. Create file chat/templates/index.html

~~~bash
nano chat/templates/index.html
~~~

<p>Edit and save</p>

```
{% load bootstrap4 %}
<!DOCTYPE html>
<html>
<head>
   <meta charset="utf-8">
    <title>Meu primeiro chat</title>
    {% bootstrap_css %}
</head>
<body>
<div class="container">
    Qual sala de chat você gostaria de entrar?</br>
        <input id="nome_sala" name="nome_sala" type="text" size="100" placeholder="Nome da sala..."></br>
    {% buttons %}
        <input id="botao" class="btn btn-primary" type="button" value="Entrar">
    {% endbuttons %}
</div>

<script>

     document.querySelector('#nome_sala').focus();
     /*Captura do evento de tecla enter*/
     document.querySelector('#nome_sala').onkeyup = function(e){
         if(e.keyCode === 13){
             document.querySelector('#botao').click();
         }
     };
    /*função anonyma para declara o nome da sala do chat*/
     document.querySelector('#botao').onclick = function(e){
         var nome_sala = document.querySelector('#nome_sala').value;
         if(nome_sala != ""){
             window.location.pathname = '/chat/' + nome_sala + '/';
         }else{
             alert('Você precisa informar o nome da sala.');
             document.querySelector('#nome_sala').focus();
         }
     };
</script>


{% bootstrap_javascript jquery='full' %}
</body>
</html>
```

### 16. Create file chat/templates/sala.html

~~~bash
nano chat/templates/sala.html
~~~

<p>Edit and save</p>

```
{% load bootstrap4 %}
<!DOCTYPE html>
<html>
<head>
   <meta charset="utf-8">
    <title>Chat</title>
    {% bootstrap_css %}
</head>
<body>
<div class="container">
    <textarea id="sala" cols="70" rows="15"></textarea><br>
    <input id="texto" type="text" size="5">
    {% buttons %}
        <input id="botao" type="button" value="Enviar">
    {% endbuttons %}

</div>


{% bootstrap_javascript jquery='full' %}

<script>
 var nome_sala = {{ nome_sala_json }};

   var chatSocket = new WebSocket(
        'ws://' + window.location.host +
        '/ws/chat/' + nome_sala + '/');

    chatSocket.onmessage = function(e){
        var dados = JSON.parse(e.data);
        var mensagem = dados['mensagem'];
        document.querySelector('#sala').value += (mensagem + '\n');
    };

    chatSocket.onclose = function(e){
        console.error('O chat encerrou de forma inesperada.');
    };

    document.querySelector('#texto').focus();
    document.querySelector('#texto').onkeyup = function(e){
        if(e.keyCode === 13){
            document.querySelector('#botao').click();
        }
    };

    document.querySelector('#botao').onclick = function(e){
        var mensagemInput = document.querySelector('#texto');
        var mensagem = mensagemInput.value;
        chatSocket.send(JSON.stringify({
            'mensagem': mensagem
        }));
        mensagemInput.value = '';
    };
</script>
</body>
</html>
```

### 17. Create file chat/consumers.py

~~~bash
nano chat/consumers.py
~~~

<p>Edit and save</p>

```
from channels.generic.websocket import AsyncWebsocketConsumer
import json


class ChatConsumer(AsyncWebsocketConsumer):
    async def connect(self):
        self.room_name = self.scope['url_route']['kwargs']['nome_sala']
        self.room_group_name = f'chat_{self.room_name}'

        # entrar na sala
        await self.channel_layer.group_add(
            self.room_group_name,
            self.channel_name
        )

        await self.accept()

    async def disconnect(self, code):
        await self.channel_layer.group_discard(
            self.room_group_name,
            self.channel_name
        )

    # recebimento de mensagem
    async def receive(self, text_data):
        text_data_json = json.loads(text_data)
        mensagem = text_data_json['mensagem']

        # enviar mensagem
        await self.channel_layer.group_send(
            self.room_group_name,
            {
                'type': 'chat_message',
                'message': mensagem
            }
        )

        # receber a mensagem

    async def chat_message(self, event):
        mensagem = event['message']

        await self.send(text_data=json.dumps({
            'mensagem': mensagem
        }))
```

### 18. Create file chat/routing.py

~~~bash
nano chat/routing.py
~~~

<p>Edit and save</p>

```
# chat/routing.py

from django.urls import re_path
from . import consumers

websocket_urlpatterns = [
    re_path(r'ws/chat/(?P<nome_sala>\w+)/$', consumers.ChatConsumer.as_asgi()),
]
```

### 19. Create file chat/urls.py

~~~bash
nano chat/urls.py
~~~

<p>Edit and save</p>

```
from django.urls import path

from .views import IndexView, SalaView

urlpatterns = [
    path('', IndexView.as_view(), name='index'),
    path('chat/<str:nome_sala>/', SalaView.as_view(), name='sala'),
]
```

### 20. Edit file chat/views.py

~~~bash
nano chat/views.py
~~~

<p>Edit and save</p>

```
from django.views.generic import TemplateView
from django.utils.safestring import mark_safe
import json


class IndexView(TemplateView):
    template_name = 'index.html'


class SalaView(TemplateView):
    template_name = 'sala.html'

    def get_context_data(self, **kwargs):
        context = super(SalaView, self).get_context_data(**kwargs)
        context['nome_sala_json'] = mark_safe(
            json.dumps(self.kwargs['nome_sala'])
        )
        return context
```

### Everything created, let's execute the project

~~~bash
docker compose up --build 
~~~

<p>If you make any changes to the Dockerfile and docker-compose.yml, we will have to update the project.</p>

~~~bash
docker compose up --build --force-recreate
~~~

### ⚠️ If you have any permission error to create <b>Data</b> folder, run commands.

~~~bash
sudo su
~~~

~~~bash
docker compose up --build --force-recreate -d
~~~

<p>
It is a very simple but functional project, you can modify and add any real improvements to a <br>
conversations project. <br>

I hope you enjoyed! See you soon on another project. Goodbye 🫰
</p>