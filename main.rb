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

get '/b2t/getnewaddress' do
  bitcoinRPC.getnewaddress
rescue RuntimeError => e
  bitcoinRPC.loadwallet('default')
  # 読み込みは一回しかしちゃだめ
  retry
end

