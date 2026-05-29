# BolaoADS

Aplicacao Ruby on Rails para bolao de palpites da Copa do Mundo.

## Requisitos

- Ruby 3.3.11
- Rails 8
- SQLite

No ambiente atual, `ruby`, `gem` e `rails` ainda nao estao no PATH. Instale o Ruby antes de rodar os comandos abaixo.

## Setup

```bash
bundle install
bin/rails db:prepare
bin/dev
```

Copie `.env.example` para `.env` e configure `FOOTBALL_API_KEY` com um token do BSD para habilitar sincronizacao com API externa. A configuracao padrao busca jogos da Copa do Mundo 2026 via `https://sports.bzzoiro.com/api/v2/events/?league_id=27&season_id=188&limit=200`.

No Windows, use:

```powershell
powershell.exe -ExecutionPolicy Bypass -File .\bin\dev.ps1
```

O comando procura uma porta livre a partir da `3000`, escuta em `0.0.0.0` e imprime:

- a URL local, como `http://127.0.0.1:3000`;
- a URL da rede local, como `http://192.168.0.88:3000`.

Para acessar de outro dispositivo, ele precisa estar na mesma rede. Se o Windows Firewall bloquear o acesso, libere o Ruby/Rails para redes privadas.

## Validacao

```bash
bin/rails test
```
