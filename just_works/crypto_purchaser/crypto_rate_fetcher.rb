require 'json'
require 'net/http'
require_relative 'crypto_exchange_exception'

##
# This class handles fetching the current crypto exchange rates for the provided currency
# from CoinBase. No authentication is currently needed for the exchange-rates endpoint.
module JustWorks
  module CryptoPurchaser
    class CryptoRateFetcher
	
	  CryptoExchangeException = JustWorks::CryptoPurchaser::CryptoExchangeException
	
	  attr_reader :last_exchange_rates, :last_fetch_timestamp

      ##
	  # Creates a new CryptoRateFetcher object and sets with last_exchange_rates (used to return the last successful fetch
	  # from memory, last_fetch_timestamp (used to mark the timestamp of the last successful fetch), 
	  # and last_fetch_successful (boolean on whether last_exchange_rates is stale or not).
	  def initialize
	    @last_exchange_rates = {}
	    @last_fetch_timestamp = nil
		@last_fetch_successful = false
	  end
	  
	  ##
	  # Method that returns a boolean as to if the last_exchange_rates is current.
	  #
	  # @return [Boolean] Whether or not last_exchange_rates is stale data
	  def last_fetch_successful?
	    @last_fetch_successful
	  end
	  
	  ##
	  # Method that will fetch the current exchange rates from coin base based on the provided currency.
	  # If successful then the JSON response will be return and saved in memory for future operations.
      # example - {"data":{"currency":"USD","rates":{"BTC":"0.3", "ETH":"1.4", "DOGE": "0.1337"}}}
      #	  
	  # Will raise CryptoExchangeException if it failed fetch the most recent exchange rates which will also
	  # set the flag last_fetch_successful to false.
	  #
	  # @param currency [String] the currency to fetch the crypto exchange rates for
	  # @return [JSON] The crypto exchange rates for the requested currency
	  def get_exchange_rates_for(currency: 'USD')
        uri = URI("https://api.coinbase.com/v2/exchange-rates?currency=#{currency}")
	    response = Net::HTTP.get_response(uri)
	
		if response.is_a?(Net::HTTPSuccess)
		  @last_exchange_rates = JSON.parse(response.body)
		  @last_fetch_timestamp = Time.now
		  @last_fetch_successful = true
		  return @last_exchange_rates
		else
		  @last_fetch_successful = false
		  err_msg = "Something went wrong when fetching exchange for #{currency}."
		  
		  begin
		    errors = JSON.parse(response.body)['errors']
			err_msg = errors.map { |error| "#{error['id']} was triggered, #{error['message']}." }.join(', ')
		  rescue JSON::ParserError => parse_error
		  ensure
		    raise CryptoExchangeException.new(err_msg)
		  end
		end
      end
	end
  end
end