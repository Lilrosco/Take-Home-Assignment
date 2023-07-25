require 'bigdecimal'
require_relative 'crypto_exchange_exception'
require_relative 'crypto_rate_fetcher'

##
# This class handles determining how much BTC and ETH a user could purchase for their
# specified amount in the currency and BTC/ETH ratio of their choice.
module JustWorks
  module CryptoPurchaser
    class CurrencyToCryptoExchange
	
      CryptoRateFetcher = JustWorks::CryptoPurchaser::CryptoRateFetcher
      CryptoExchangeException = JustWorks::CryptoPurchaser::CryptoExchangeException
	  
      attr_reader :btc_ratio, :eth_ratio, :currency
	
      ##
      # Creates a new CurrencyToCryptoExchange object which will determine how much BTC and ETH a user
      # could potentially purchase based on the currency specified.
      # Both ratios sum must be 0 <= ratio <= 1.
      #
      # @param btc_ratio [String] the percentage to allocate funds to when determining how much BTC can be purchased.
      # @param eth_ratio [String] the percentage to allocate funds to when determining how much ETH can be purchased.
      # @param currency [String] the currency to fetch and determine a potential crypto purchase split against.
      def initialize(btc_ratio: '0.7', eth_ratio: '0.3', currency: 'USD')
        @btc_ratio = BigDecimal(btc_ratio).to_f
        raise ArgumentError.new("btc_ratio cannot be less than 0.") if @btc_ratio < 0

        @eth_ratio = BigDecimal(eth_ratio).to_f
        raise ArgumentError.new("eth_ratio cannot be less than 0.") if @eth_ratio < 0
		
        raise CryptoExchangeException.new(
          "btc_ratio: #@btc_ratio + eth_ratio: #@eth_ratio does not equal 1"
        ) unless @btc_ratio + @eth_ratio == 1
		
        @currency = currency
        @crypto_rate_fetcher = CryptoRateFetcher.new
      end
	  
      ##
      # Method to update the current currency to a new value.
      #
      # @param currency [String] the new currency to be set.
      def update_currency(currency: )
        # Wanted to add a currency validation

        @currency = currency
      end
	  
      ##
      # Method to update the BTC and ETH ratio.
      # Both ratios sum must be 0 <= ratio <= 1.
      #
      # @param btc_ratio [String] the new BTC ration to be used.
      # @param eth_ratio [String] the new ETH ration to be used.
      def update_btc_and_eth_ratio(btc_ratio:, eth_ratio:)
        temp_btc_ratio = BigDecimal(btc_ratio).to_f
        raise ArgumentError.new("btc_ratio cannot be less than 0.") if temp_btc_ratio < 0

        temp_eth_ratio = BigDecimal(eth_ratio).to_f
        raise ArgumentError.new("eth_ratio cannot be less than 0.") if temp_eth_ratio < 0
		
        raise CryptoExchangeException.new(
          "btc_ratio: #{temp_btc_ratio} + eth_ratio: #{temp_eth_ratio} does not equal 1"
        ) unless temp_btc_ratio + temp_eth_ratio == 1
		
        @btc_ratio = temp_btc_ratio
        @eth_ratio = temp_eth_ratio
      end

	  
      ##
      # Method to calculate based on the provided amount, the current currency, and the current ratios
      # how much BTC and ETH can potentially be purchased.
      # Will raise an ArgumentError if the amount passed in is a negative value
      #
      # @param amount [Numeric] the amount of money to be used in calculations.
      # @return [Hash<Symbol, Float>] the amount of BTC and ETH that could be purchased with current rates.
      def determine_btc_and_eth_purchase(amount: 0)
        money_value = BigDecimal(amount)
        raise ArgumentError.new("Amount cannot be less than 0.") if amount < 0

        rates = @crypto_rate_fetcher.get_exchange_rates_for(
          currency: @currency
        )['data']['rates']

        btc_exchange_rate = rates['BTC'].to_f
        eth_exchange_rate = rates['ETH'].to_f

        conversion_hash = { :btc => 0, :eth => 0 }
		
        btc_spending_amount = (money_value * @btc_ratio).to_f
        eth_spending_amount = (money_value * @eth_ratio).to_f
		  
        conversion_hash[:btc] = btc_spending_amount * btc_exchange_rate
        conversion_hash[:eth] = eth_spending_amount * eth_exchange_rate
		
        conversion_hash
      end
    end
  end
end