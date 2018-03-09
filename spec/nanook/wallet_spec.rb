RSpec.describe Nanook::Wallet do

  let(:uri) { Nanook::Rpc::DEFAULT_URI }
  let(:account_id) { "xrb_3e3j5tkog48pnny9dmfzj1r16pg8t1e76dz5tmac6iq689wyjfpi00000000" }
  let(:wallet_id) { "000D1BAEC8EC208142C99059B393051BAC8380F9B5A2E6B2489A277D81789F3F" }
  let(:block_id) { "000D1BAEC8EC208142C99059B393051BAC8380F9B5A2E6B2489A277D81789F3F" }
  let(:headers) {
    {
      'Accept'=>'*/*',
      'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
      'Content-Type'=>'application/json',
      'User-Agent'=>'Ruby nanook gem'
    }
  }

  def stub_valid_account_check
    stub_request(:post, "http://localhost:7076/").
    with(
      body: "{\"action\":\"wallet_contains\",\"wallet\":\"000D1BAEC8EC208142C99059B393051BAC8380F9B5A2E6B2489A277D81789F3F\",\"account\":\"xrb_3e3j5tkog48pnny9dmfzj1r16pg8t1e76dz5tmac6iq689wyjfpi00000000\"}",
      headers: {
      'Accept'=>'*/*',
      'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
      'Content-Type'=>'application/json',
      'User-Agent'=>'Ruby nanook gem'
      }).
    to_return(status: 200, body: "{\"exists\":\"1\"}", headers: {})
  end

  it "wallet create" do
    stub_request(:post, uri).with(
      body: "{\"action\":\"wallet_create\"}",
      headers: headers
    ).to_return(
      status: 200,
      body: "{\"wallet\":\"000D1BAEC8EC208142C99059B393051BAC8380F9B5A2E6B2489A277D81789F3F\"}",
      headers: {}
    )

    expect(Nanook.new.wallet.create).to eq "000D1BAEC8EC208142C99059B393051BAC8380F9B5A2E6B2489A277D81789F3F"
  end

  it "wallet destroy" do
    stub_request(:post, uri).with(
      body: "{\"action\":\"wallet_destroy\",\"wallet\":\"#{wallet_id}\"}",
      headers: headers
    ).to_return(
      status: 200,
      body: "{}",
      headers: {}
    )

    expect(Nanook.new.wallet(wallet_id).destroy).to be true
  end

  it "wallet export" do
    stub_request(:post, uri).with(
      body: "{\"action\":\"wallet_export\",\"wallet\":\"#{wallet_id}\"}",
      headers: headers
    ).to_return(
      status: 200,
      body: "{\"json\":\"{\\\"0000000000000000000000000000000000000000000000000000000000000000\\\": \\\"0000000000000000000000000000000000000000000000000000000000000001\\\"}\"}",
      headers: {}
    )

    expect(Nanook.new.wallet(wallet_id).export).to eq '{"0000000000000000000000000000000000000000000000000000000000000000": "0000000000000000000000000000000000000000000000000000000000000001"}'
  end

  it "wallet contains? when true" do
    stub_request(:post, uri).with(
      body: "{\"action\":\"wallet_contains\",\"wallet\":\"#{wallet_id}\",\"account\":\"#{account_id}\"}",
      headers: headers
    ).to_return(
      status: 200,
      body: "{\"exists\":\"1\"}",
      headers: {}
    )

    expect(Nanook.new.wallet(wallet_id).contains?(account_id)).to be true
  end

  it "wallet contains? when false" do
    stub_request(:post, uri).with(
      body: "{\"action\":\"wallet_contains\",\"wallet\":\"#{wallet_id}\",\"account\":\"#{account_id}\"}",
      headers: headers
    ).to_return(
      status: 200,
      body: "{\"exists\":\"0\"}",
      headers: {}
    )

    expect(Nanook.new.wallet(wallet_id).contains?(account_id)).to be false
  end

  it "wallet locked? when it is not locked" do
    stub_request(:post, uri).with(
      body: "{\"action\":\"wallet_locked\",\"wallet\":\"#{wallet_id}\"}",
      headers: headers
    ).to_return(
      status: 200,
      body: "{\"locked\":\"0\"}",
      headers: {}
    )

    expect(Nanook.new.wallet(wallet_id).locked?).to be false
  end

  it "wallet locked? when it is locked" do
    stub_request(:post, uri).with(
      body: "{\"action\":\"wallet_locked\",\"wallet\":\"#{wallet_id}\"}",
      headers: headers
    ).to_return(
      status: 200,
      body: "{\"locked\":\"1\"}",
      headers: {}
    )

    expect(Nanook.new.wallet(wallet_id).locked?).to be true
  end

  it "wallet unlock" do
    stub_request(:post, uri).with(
      body: "{\"action\":\"password_enter\",\"wallet\":\"#{wallet_id}\",\"password\":\"test\"}",
      headers: headers
    ).to_return(
      status: 200,
      body: "{\"valid\":\"1\"}",
      headers: {}
    )

    expect(Nanook.new.wallet(wallet_id).unlock("test")).to be true
  end

  it "wallet change password" do
    stub_request(:post, uri).with(
      body: "{\"action\":\"password_change\",\"wallet\":\"#{wallet_id}\",\"password\":\"test\"}",
      headers: headers
    ).to_return(
      status: 200,
      body: "{\"changed\":\"1\"}",
      headers: {}
    )

    expect(Nanook.new.wallet(wallet_id).change_password("test")).to be true
  end

  it "wallet send payment" do
    stub_valid_account_check

    stub_request(:post, uri).with(
      body: "{\"action\":\"send\",\"wallet\":\"#{wallet_id}\",\"source\":\"#{account_id}\",\"destination\":\"#{account_id}\",\"amount\":\"2000000000000000000000000000000\",\"id\":\"7081e2b8fec9146e\"}",
      headers: headers
    ).to_return(
      status: 200,
      body: "{\"block\":\"#{block_id}\"}",
      headers: {}
    )

    response = Nanook.new.wallet(wallet_id).pay(from: account_id, to: account_id, amount: 2, id:"7081e2b8fec9146e")
    expect(response).to eq block_id
  end

  it "wallet account receive latest pending payment" do
    stub_valid_account_check

    stub_request(:post, uri).with(
      body: "{\"action\":\"pending\",\"account\":\"#{account_id}\",\"count\":\"1\"}",
      headers: headers
    ).to_return(
      status: 200,
      body: "{\"blocks\":[\"#{block_id}\"]}",
      headers: {}
    )

    stub_request(:post, uri).with(
      body: "{\"action\":\"receive\",\"wallet\":\"#{wallet_id}\",\"account\":\"#{account_id}\",\"block\":\"#{block_id}\"}",
      headers: headers
    ).to_return(
      status: 200,
      body: "{\"block\":\"#{block_id}\"}",
      headers: {}
    )

    response = Nanook.new.wallet(wallet_id).receive(into: account_id)
    expect(response).to eq block_id
  end

  it "wallet account receive latest pending payment when no payment is pending" do
    stub_valid_account_check

    stub_request(:post, uri).with(
      body: "{\"action\":\"pending\",\"account\":\"#{account_id}\",\"count\":\"1\"}",
      headers: headers
    ).to_return(
      status: 200,
      body: "{\"blocks\":\"\"}",
      headers: {}
    )

    expect(Nanook.new.wallet(wallet_id).receive(into: account_id)).to be false
  end

  it "wallet account receive payment with block" do
    stub_valid_account_check

    stub_request(:post, uri).with(
      body: "{\"action\":\"receive\",\"wallet\":\"#{wallet_id}\",\"account\":\"#{account_id}\",\"block\":\"#{block_id}\"}",
      headers: headers
    ).to_return(
      status: 200,
      body: "{\"block\":\"#{block_id}\"}",
      headers: {}
    )

    response = Nanook.new.wallet(wallet_id).receive(block_id, into: account_id)
    expect(response).to eq block_id
  end

  it "wallet balance with account break down" do
    stub_request(:post, uri).with(
      body: "{\"action\":\"wallet_balances\",\"wallet\":\"#{wallet_id}\"}",
      headers: headers
    ).to_return(
      status: 200,
      body: "{\"balances\":{
        \"xrb_3e3j5tkog48pnny9dmfzj1r16pg8t1e76dz5tmac6iq689wyjfpi00000000\":{
          \"balance\":\"10000\",
          \"pending\":\"10000\"
        }
      }}",
      headers: {}
    )

    expect(Nanook.new.wallet(wallet_id).balance(account_break_down: true)).to have_key :xrb_3e3j5tkog48pnny9dmfzj1r16pg8t1e76dz5tmac6iq689wyjfpi00000000
  end

  it "wallet balance with no account break down" do
    stub_request(:post, uri).with(
      body: "{\"action\":\"wallet_balance_total\",\"wallet\":\"#{wallet_id}\"}",
      headers: headers
    ).to_return(
      status: 200,
      body: "{\"balance\":\"10000\",\"pending\":\"10000\"}",
      headers: {}
    )

    expect(Nanook.new.wallet(wallet_id).balance).to have_key :balance
  end

end
