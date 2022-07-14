# b2t.server

BTC to TPC server.

```mermaid
sequenceDiagram
  autonumber
  actor User
  User ->> Client: GET /b2t/execute
  Client ->> Server: GET /b2t/bitcoin/getnewaddress
  Server ->> Client: Return new Bitcoin address
  Client -->> Client: Create payment transaction
  Client -->> Client: Get new Tapyrus address
  Client ->> Server: GET /b2t/execute
  Server -->> Server: Create receipt transaction
  Server ->> Client: Return receipt transaction id
  Client ->> User: Return both transaction id
```

## setup

```bash
$ docker compose up -d
```

## usage

localhost:8910 に向けて色々投げる、[専用クライアント](https://github.com/shmn7iii/b2t.client)駆動を想定

- ヘルスチェック  
  http://localhost:4567/health
