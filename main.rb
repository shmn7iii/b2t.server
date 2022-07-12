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
  payment_txid = params['payment_txid']
  receipt_address = params['receipt_address']
  amount = params['amount']
  tapyrusRPC.sendtoaddress(receipt_address, amount)
end
