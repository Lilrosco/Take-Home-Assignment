require 'net/http'
require './just_works/crypto_purchaser'

CryptoRateFetcher ||= JustWorks::CryptoPurchaser::CryptoRateFetcher
CryptoExchangeException ||= JustWorks::CryptoPurchaser::CryptoExchangeException

describe CryptoRateFetcher do

  before do
    @fetcher = CryptoRateFetcher.new
  end

  it "returns false when checking last_fetch_successful without fetching rates" do
    expect(@fetcher.last_fetch_successful?).to be false
  end
  
  it "returns empty hash when checking last_exchange_rates without fetching rates" do
    expect(@fetcher.last_exchange_rates).to eq({})
  end
  
  it "returns nil when checking last_fetch_timestamp without fetching rates" do
    expect(@fetcher.last_fetch_timestamp).to be nil
  end
  
  it "returns true when checking last_fetch_successful after successfully fetching rates" do
    response = Net::HTTPSuccess.new(1.0, '200', 'OK')
    expect_any_instance_of(Net::HTTP).to receive(:request) { response }
    expect(response).to receive(:body) { '{"data": "Successful fetch"}' }

    @fetcher.get_exchange_rates_for(currency: 'USD')
    expect(@fetcher.last_fetch_successful?).to be true
  end
  
  it "raises CryptoExchangeException when failing to fetch rates" do
    response = Net::HTTPBadRequest.new(1.0, '400', 'BADREQUEST')
    expect_any_instance_of(Net::HTTP).to receive(:request) { response }
    expect(response).to receive(:body) { '{"errors":[{"id":"invalid_request","message":"Currency is invalid"}]}' }

    expect { @fetcher.get_exchange_rates_for(currency: 'DSU') }.to raise_error(
      CryptoExchangeException, /invalid_request was triggered, Currency is invalid./
    )
    expect(@fetcher.last_fetch_successful?).to be false
  end
  
  it "raises CryptoExchangeException when failing to fetch rates and response is not a JSON" do
    currency = 'USD'
    response = Net::HTTPBadRequest.new(1.0, '400', 'BADREQUEST')
    expect_any_instance_of(Net::HTTP).to receive(:request) { response }
    expect(response).to receive(:body) { 'Bad JSON' }

    expect { @fetcher.get_exchange_rates_for(currency: currency) }.to raise_error(
      CryptoExchangeException, "Something went wrong when fetching exchange for #{currency}."
    )
    expect(@fetcher.last_fetch_successful?).to be false
  end
  
  it "returns stall data when failing to fetch rates after the " do
    response = Net::HTTPSuccess.new(1.0, '200', 'OK')
    allow_any_instance_of(Net::HTTP).to receive(:request) { response }
    allow(response).to receive(:body) { '{"data":{"currency":"USD","rates":{"BTC":"0.7777777777777"}}}' }

    original_rates = @fetcher.get_exchange_rates_for(currency: 'USD')
    expect(@fetcher.last_fetch_successful?).to be true
	
    response = Net::HTTPBadRequest.new(1.0, '400', 'BADREQUEST')
    expect_any_instance_of(Net::HTTP).to receive(:request) { response }
    expect(response).to receive(:body) { '{"errors":[{"id":"invalid_request","message":"Currency is invalid"}]}' }

    expect { @fetcher.get_exchange_rates_for(currency: 'DSU') }.to raise_error(
      CryptoExchangeException, /invalid_request was triggered, Currency is invalid./
    )
    expect(@fetcher.last_fetch_successful?).to be false
    expect(@fetcher.last_fetch_timestamp).not_to be nil
	
    stale_rates = @fetcher.last_exchange_rates
    expect(stale_rates).not_to eq({})
    expect(stale_rates).to eq(original_rates)
  end
end