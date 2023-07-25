require_relative 'just_works/crypto_purchaser'

inputs = [
  # Using default 70/30 split for BTC/ETH and USD currency
  { amount: 10_000, btc_ratio: '0.7', eth_ratio: '0.3', currency: 'USD' },

  # Using negative USD amount
  { amount: -1, btc_ratio: '0.7', eth_ratio: '0.3', currency: 'USD' },

  # Using bad input for ratios
  { amount: 10_000, btc_ratio: 'Pancakes', eth_ratio: 'Waffles', currency: 'USD' },
  
  # Using negative input for ratios
  { amount: 10_000, btc_ratio: '-0.1', eth_ratio: '-0.9', currency: 'USD' },

  # default 70/30 split for BTC/ETH but JPY currency
  { amount: 10_000, btc_ratio: '0.7', eth_ratio: '0.3', currency: 'JPY' },

  # Using a bad currency
  { amount: 10_000, btc_ratio: '0.7', eth_ratio: '0.3', currency: 'BAD' },

  # Using 51/49 split for BTC/ETH and USD currency
  { amount: 10_000, btc_ratio: '0.51', eth_ratio: '0.49', currency: 'USD' },

  # Using 20/25 split for BTC/ETH and USD currency, will fail given 55% of funds are not used
  { amount: 10_000, btc_ratio: '0.2', eth_ratio: '0.25', currency: 'USD' },

  # Using 99/99 split for BTC/ETH and USD currency, bad split
  { amount: 10_000, btc_ratio: '0.99', eth_ratio: '0.99', currency: 'USD' },

  # default 70/30 split for BTC/ETH but amount is $0 for USD
  { amount: 0, btc_ratio: '0.7', eth_ratio: '0.3', currency: 'USD' },
]

inputs.each_with_index do |input, idx|
  begin
    crypto_exchange = JustWorks::CryptoPurchaser::CurrencyToCryptoExchange.new(
      btc_ratio: input[:btc_ratio],
      eth_ratio: input[:eth_ratio],
      currency: input[:currency]
    )

    purchase_hash = crypto_exchange.determine_btc_and_eth_purchase(
      amount: input[:amount]
    )

    current_currency = crypto_exchange.currency
    btc_ratio = crypto_exchange.btc_ratio
    eth_ratio = crypto_exchange.eth_ratio

    puts "#{idx + 1}) For #{input[:amount]} #{current_currency} and a BTC/ETH split of " \
      "#{btc_ratio}/#{eth_ratio}, purchase BTC: #{purchase_hash[:btc]} & ETH: #{purchase_hash[:eth]}"
  rescue JustWorks::CryptoPurchaser::CryptoExchangeException => ex
    puts "#{idx + 1}) " + ex.message
  rescue ArgumentError => ag
    puts "#{idx + 1}) Bad Input: #{ag.message}"
  ensure
    puts ""
  end
end