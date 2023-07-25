require './just_works/crypto_purchaser'

CryptoExchangeException ||= JustWorks::CryptoPurchaser::CryptoExchangeException

describe CryptoExchangeException do
  before do
    @err_msg = "Something Happened."
  end
  
  it "returns expected error message" do
    @exception = CryptoExchangeException.new(@err_msg)
    expect(@exception.message).to eq @err_msg
  end
end