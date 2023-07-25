##
# This class handles generic exceptions that can occur when fetching or determining
# potential crypto exchanges.

module JustWorks
  module CryptoPurchaser
    class CryptoExchangeException < StandardError
	  
	  ##
	  # Creates a new StandardError with a passed in message
	  # @param message [String] the message describing the error that occurred
      def initialize(message)
        super(message)
      end
    end
  end
end