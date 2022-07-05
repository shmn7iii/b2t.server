# b2t.server

BTC to TPC server.

## setup

```bash
$ docker compose build
$ docker compose up -d

# ログが見たい
$ docker compose logs -f

# 初回のみ
$ docker compose exec bitcoind bitcoin-cli -signet -rpcuser=hoge -rpcpassword=hoge createwallet default
```

## usage

localhost:8910 に向けて色々投げる、専用クライアント駆動を想定
