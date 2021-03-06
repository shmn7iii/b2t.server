require 'sinatra'
require 'sinatra/reloader' if development?
require 'sinatra/json'
require 'bitcoin'
require 'tapyrus'
require 'dotenv'

Dotenv.load
Bitcoin.chain_params = :signet
Tapyrus.chain_params = :prod

def bitcoinRPC
  bitcoin_rpc_config = { schema: ENV['bitcoind_rpc_schema'], host: ENV['bitcoind_rpc_host'], port: ENV['bitcoind_rpc_port'],
                         user: ENV['bitcoind_rpc_user'], password: ENV['bitcoind_rpc_password'] }
  Bitcoin::RPC::BitcoinCoreClient.new(bitcoin_rpc_config)
end

def tapyrusRPC
  tapyrus_rpc_config = { schema: ENV['tapyrusd_rpc_schema'], host: ENV['tapyrusd_rpc_host'], port: ENV['tapyrusd_rpc_port'],
                         user: ENV['tapyrusd_rpc_user'], password: ENV['tapyrusd_rpc_password'] }
  Tapyrus::RPC::TapyrusCoreClient.new(tapyrus_rpc_config)
end

# laod bitcoin wallet
begin
  bitcoinRPC.loadwallet('default')
rescue RuntimeError => e
  case JSON.parse(e.message)['code']
  when -18 # => Wallet file verification failed. (Path does not exist)
    bitcoinRPC.createwallet('default')
  when -28 # => Loading block index.
    sleep 1
    retry
  end
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
