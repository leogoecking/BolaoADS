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
bin/rails server
```

Copie `.env.example` para `.env` e configure `FOOTBALL_API_KEY` para habilitar sincronizacao com API externa.

## Validacao

```bash
bin/rails test
```
