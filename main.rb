require 'sinatra'
require 'json'
require 'net/http'
require 'bitcoin'
require 'tapyrus'

Bitcoin.chain_params = :signet
Tapyrus.chain_params = :prod

def bitcoinRPC
  bitcoin_rpc_config = { schema: 'http', host: 'bitcoind', port: 38332, user: 'hoge', password: 'hoge' }
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
  'Hi there! :)'
end

get '/health' do
  health = { bitcoin: bitcoinRPC.getblockchaininfo, tapyrus: tapyrusRPC.getblockchaininfo }.to_json
end

# wallet が自動生成されません
# $ docker compose exec bitcoind bitcoin-cli -signet -rpcuser=hoge -rpcpassword=hoge createwallet default
get '/b2t/getnewaddress' do
  begin
    bitcoinRPC.getnewaddress
  rescue RuntimeError => err
    bitcoinRPC.loadwallet('default')
    # 読み込みは一回しかしちゃだめ
    retry
  end
end

get '/b2t/execute' do
  bitcoinRPC.loadwallet('default')
  payment_txid = params['payment_txid']
  recieve_tpc_address = params['recieve_tpc_address']

  # 本当はここで payment_tx が正当かどうか検証したい

  # payment_tx の送付額を取得
  # 今持ってるUTXOと比較してやるべきかこれ
  utxos =bitcoinRPC.listunspent.select{|x| x["txid"]==payment_txid}
  vout = utxos[0]['vout']
  payment_tx = bitcoinRPC.getrawtransaction(payment_txid, true)
  amount = payment_tx['vout'][vout]['value']

  # 同額のTPCを送付
  # 本当はガバナンストークンがいいけどとりあえずTPC
  receipt_txid = tapyrusRPC.sendtoaddress(recieve_tpc_address, amount)

  # 返却
  receipt_txid
end
