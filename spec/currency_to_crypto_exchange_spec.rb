require 'json'
require './just_works/crypto_purchaser'

CurrencyToCryptoExchange ||= JustWorks::CryptoPurchaser::CurrencyToCryptoExchange
CryptoExchangeException ||= JustWorks::CryptoPurchaser::CryptoExchangeException

describe CurrencyToCryptoExchange do

  before do
    @btc_ratio = '0.7'
	@eth_ratio = '0.3'
	@currency = 'USD'
	@amount = 10_000
	@data = '{"data":{"currency":"USD","rates":{"BTC":"0.7777777777777", "ETH":"1.5000000000000"}}}'
	@rates = JSON.parse(@data)
	@btc_exchange_rate = @rates['data']['rates']['BTC'].to_f
    @eth_exchange_rate = @rates['data']['rates']['ETH'].to_f
	
	@response = Net::HTTPSuccess.new(1.0, '200', 'OK')
	allow_any_instance_of(Net::HTTP).to receive(:request) { @response }
	allow(@response).to receive(:body) { @data } 
  end
  
  it "returns expected BTC/ETH that can be bought for 10000 USD" do
	crypto_exchange = CurrencyToCryptoExchange.new(
	  btc_ratio: @btc_ratio,
	  eth_ratio: @eth_ratio,
	  currency: @currency
	)

    purchase_hash = crypto_exchange.determine_btc_and_eth_purchase(
	  amount: @amount
	)
	
    current_currency = crypto_exchange.currency
    btc_ratio = crypto_exchange.btc_ratio
    eth_ratio = crypto_exchange.eth_ratio

	expect(current_currency).to eq(@currency)
	expect(btc_ratio).to eq(@btc_ratio.to_f)
	expect(eth_ratio).to eq(@eth_ratio.to_f)
	
	btc_spending_amount = @amount.to_f * btc_ratio
	eth_spending_amount = @amount.to_f * eth_ratio

    expect(purchase_hash[:btc]).to eq(btc_spending_amount * @btc_exchange_rate)
	expect(purchase_hash[:eth]).to eq(eth_spending_amount * @eth_exchange_rate)
  end
  
  it "returns expected BTC/ETH that can be bought for 0 USD" do
    @amount = 0

	crypto_exchange = CurrencyToCryptoExchange.new(
	  btc_ratio: @btc_ratio,
	  eth_ratio: @eth_ratio,
	  currency: @currency
	)

    purchase_hash = crypto_exchange.determine_btc_and_eth_purchase(
	  amount: @amount
	)
	
    current_currency = crypto_exchange.currency
    btc_ratio = crypto_exchange.btc_ratio
    eth_ratio = crypto_exchange.eth_ratio

	expect(current_currency).to eq(@currency)
	expect(btc_ratio).to eq(@btc_ratio.to_f)
	expect(eth_ratio).to eq(@eth_ratio.to_f)
	
	btc_spending_amount = @amount.to_f * btc_ratio
	eth_spending_amount = @amount.to_f * eth_ratio

    expect(purchase_hash[:btc]).to eq(btc_spending_amount * @btc_exchange_rate)
	expect(purchase_hash[:eth]).to eq(eth_spending_amount * @eth_exchange_rate)
  end
  
  it "returns expected BTC/ETH that can be bought for 10000 EUR after updating currency from USD" do
	@data = '{"data":{"currency":"EUR","rates":{"BTC":"0.333333333333333", "ETH":"2.5000000"}}}'
	@rates = JSON.parse(@data)
	@btc_exchange_rate = @rates['data']['rates']['BTC'].to_f
    @eth_exchange_rate = @rates['data']['rates']['ETH'].to_f
	allow(@response).to receive(:body) { @data } 

	crypto_exchange = CurrencyToCryptoExchange.new(
	  btc_ratio: @btc_ratio,
	  eth_ratio: @eth_ratio,
	  currency: @currency
	)
	
	current_currency = crypto_exchange.currency
	expect(current_currency).to eq(@currency)
	
	@currency = 'EUR'
	crypto_exchange.update_currency(currency: @currency)

    purchase_hash = crypto_exchange.determine_btc_and_eth_purchase(
	  amount: @amount
	)
	
    current_currency = crypto_exchange.currency
    btc_ratio = crypto_exchange.btc_ratio
    eth_ratio = crypto_exchange.eth_ratio

	expect(current_currency).to eq(@currency)
	expect(btc_ratio).to eq(@btc_ratio.to_f)
	expect(eth_ratio).to eq(@eth_ratio.to_f)
	
	btc_spending_amount = @amount.to_f * btc_ratio
	eth_spending_amount = @amount.to_f * eth_ratio

    expect(purchase_hash[:btc]).to eq(btc_spending_amount * @btc_exchange_rate)
	expect(purchase_hash[:eth]).to eq(eth_spending_amount * @eth_exchange_rate)
  end
  
  it "raises ArgumentError when amount is less than 0" do
    @amount = -1

	crypto_exchange = CurrencyToCryptoExchange.new(
	  btc_ratio: @btc_ratio,
	  eth_ratio: @eth_ratio,
	  currency: @currency
	)
	
	expect {
	  purchase_hash = crypto_exchange.determine_btc_and_eth_purchase(
	    amount: @amount
	  )
	}.to raise_error(ArgumentError, /Amount cannot be less than 0./)
  end
  
  it "raises ArgumentError when btc_ratio and eth_ratio are not numeric" do
    @btc_ratio = "Pancakes"
	@eth_ratio = "Waffles"
	
	expect {
	  CurrencyToCryptoExchange.new(
	    btc_ratio: @btc_ratio,
	    eth_ratio: @eth_ratio,
	    currency: @currency
	  )
	}.to raise_error(ArgumentError)
  end
  
  it "raises ArgumentError when btc_ratio is a negative value" do
    @btc_ratio = "-0.7"
	@eth_ratio = "1.7"
	
	expect {
	  CurrencyToCryptoExchange.new(
	    btc_ratio: @btc_ratio,
	    eth_ratio: @eth_ratio,
	    currency: @currency
	  )
	}.to raise_error(ArgumentError, /btc_ratio cannot be less than 0./)
  end
  
  it "raises ArgumentError when eth_ratio is a negative value" do
    @btc_ratio = "1.7"
	@eth_ratio = "-0.7"
	
	expect {
	  CurrencyToCryptoExchange.new(
	    btc_ratio: @btc_ratio,
	    eth_ratio: @eth_ratio,
	    currency: @currency
	  )
	}.to raise_error(ArgumentError, /eth_ratio cannot be less than 0./)
  end
  
  it "raises ArgumentError when btc_ratio and eth_ratio are changed to not be numeric" do
	crypto_exchange = CurrencyToCryptoExchange.new(
	  btc_ratio: @btc_ratio,
	  eth_ratio: @eth_ratio,
	  currency: @currency
	)
	
	@btc_ratio = "Pancakes"
	@eth_ratio = "Waffles"
	
	expect {
	  crypto_exchange.update_btc_and_eth_ratio(btc_ratio: @btc_ratio, eth_ratio: @eth_ratio) 
	}.to raise_error(ArgumentError)
  end
  
  it "raises ArgumentError when btc_ratio is changed to be a negative value" do
    crypto_exchange = CurrencyToCryptoExchange.new(
	  btc_ratio: @btc_ratio,
	  eth_ratio: @eth_ratio,
	  currency: @currency
	)

    @btc_ratio = "-0.7"
	
	expect {
	  crypto_exchange.update_btc_and_eth_ratio(btc_ratio: @btc_ratio, eth_ratio: @eth_ratio) 
	}.to raise_error(ArgumentError, /btc_ratio cannot be less than 0./)
  end
  
  it "raises ArgumentError when eth_ratio is a negative value" do
    crypto_exchange = CurrencyToCryptoExchange.new(
	  btc_ratio: @btc_ratio,
	  eth_ratio: @eth_ratio,
	  currency: @currency
	)

	@eth_ratio = "-0.7"
	
	expect {
	  crypto_exchange.update_btc_and_eth_ratio(btc_ratio: @btc_ratio, eth_ratio: @eth_ratio) 
	}.to raise_error(ArgumentError, /eth_ratio cannot be less than 0./)
  end
  
  it "raises CryptoExchangeException when btc_ratio and eth_ratio do not add up to 1" do
    @btc_ratio = "0.2"
	@eth_ratio = "0.25"
	
	expect {
	  CurrencyToCryptoExchange.new(
	    btc_ratio: @btc_ratio,
	    eth_ratio: @eth_ratio,
	    currency: @currency
	  )
	}.to raise_error(CryptoExchangeException, "btc_ratio: #@btc_ratio + eth_ratio: #@eth_ratio does not equal 1")
  end
  
  it "raises CryptoExchangeException if failed to fetch rates" do
    @currency = 'DSU'
	@response = Net::HTTPBadRequest.new(1.0, '400', 'BADREQUEST')
	expect_any_instance_of(Net::HTTP).to receive(:request) { @response }
	expect(@response).to receive(:body) { '{"errors":[{"id":"invalid_request","message":"Currency is invalid"}]}' } 
	
	crypto_exchange = CurrencyToCryptoExchange.new(
	  btc_ratio: @btc_ratio,
	  eth_ratio: @eth_ratio,
	  currency: @currency
	)

	expect {
	  purchase_hash = crypto_exchange.determine_btc_and_eth_purchase(
	    amount: @amount
	  )
	}.to raise_error(CryptoExchangeException, /invalid_request was triggered, Currency is invalid./)
  end
end