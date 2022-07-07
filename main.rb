require 'sinatra'
require 'sinatra/reloader' if development?
require 'sinatra/json'
require 'bitcoin'
require 'tapyrus'

Bitcoin.chain_params = :signet
Tapyrus.chain_params = :prod

def bitcoinRPC
  bitcoin_rpc_config = { schema: 'http', host: 'bitcoind', port: 38_332, user: 'hoge', password: 'hoge' }
  Bitcoin::RPC::BitcoinCoreClient.new(bitcoin_rpc_config)
end

def tapyrusRPC
  tapyrus_rpc_config = { schema: 'http', host: 'tapyrusd', port: 2377, user: 'hoge', password: 'hoge' }
  Tapyrus::RPC::TapyrusCoreClient.new(tapyrus_rpc_config)
end

configure do
  set :bind, '0.0.0.0'
end

get '/' do
  "Hi there! I'm server :)"
end

get '/health' do
  data = {
    bitcoin: {
      chain: bitcoinRPC.getblockchaininfo['chain'],
      blockcount: bitcoinRPC.getblockcount
    },
    tapyrus: {
      chain: tapyrusRPC.getblockchaininfo['chain'],
      blockcount: tapyrusRPC.getblockcount
    }
  }
  json data
end

get '/b2t/listunspent' do
  data = {
    bitcoin: bitcoinRPC.listunspent,
    tapyrus: tapyrusRPC.listunspent
  }
  json data
end

get '/b2t/bitcoin/getrawtransaction' do
  data = bitcoinRPC.getrawtransaction(params['txid'], true)
  json data
end

get '/b2t/tapyrus/getrawtransaction' do
  data = tapyrusRPC.getrawtransaction(params['txid'], true)
  json data
end

get '/b2t/bitcoin/getnewaddress' do
  bitcoinRPC.getnewaddress
rescue RuntimeError => e
  bitcoinRPC.loadwallet('default')
  retry
end

get '/b2t/tapyrus/getnewaddress' do
  tapyrusRPC.getnewaddress
end

get '/b2t/execute' do
  # bitcoinRPC.loadwallet('default')
  payment_txid = params['payment_txid']
  receipt_address = params['receipt_address']
  amount = params['amount']

  # 本当はここで payment_tx が正当かどうか検証したい

  # 本当はここでもらったTXIDから読み取ってamount取得〜とかしたかったけど、
  # 対象TXがサーバーサイドでまだ確認できなくてエラーとか起こってどうしようもない
  # listunspentも未取り込みTXは出てこないし

  # payment_tx の送付額を取得
  # payment_tx = bitcoinRPC.getrawtransaction(payment_txid, true)
  # amount = payment_tx['vout'][vout]['value']

  # # 同額のTPCを送付
  # # 本当はガバナンストークンがいいけどとりあえずTPC
  receipt_txid = tapyrusRPC.sendtoaddress(receipt_address, amount)

  # # 返却
  receipt_txid
end
