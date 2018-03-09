class Nanook
  class Wallet

    def initialize(rpc, wallet)
      @rpc = rpc
      @wallet = wallet
    end

    def account(account=nil)
      Nanook::WalletAccount.new(@rpc, @wallet, account)
    end

    def accounts
      wallet_required!
      response = rpc(:account_list)[:accounts]
      Nanook::Util.coerce_empty_string_to_type(response, Array)
    end

    def balance(account_break_down: false)
      wallet_required!
      if account_break_down
        Nanook::Util.coerce_empty_string_to_type(rpc(:wallet_balances)[:balances], Hash)
      else
        rpc(:wallet_balance_total)
      end
    end

    def create
      rpc(:wallet_create)[:wallet]
    end

    def destroy
      wallet_required!
      rpc(:wallet_destroy)
      true
    end

    # Returns string of JSON
    def export
      wallet_required!
      rpc(:wallet_export)[:json]
    end

    def contains?(account)
      wallet_required!
      response = rpc(:wallet_contains, account: account)
      !response.empty? && response[:exists] == 1
    end

    def pay(from:, to:, amount:, id:)
      wallet_required!
      validate_wallet_contains_account!(from)
      account(from).pay(to: to, amount: amount, id: id)
    end

    def receive(block=nil, into:)
      wallet_required!
      validate_wallet_contains_account!(into)
      account(into).receive(block)
    end

    def locked?
      wallet_required!
      response = rpc(:wallet_locked)
      !response.empty? && response[:locked] != 0
    end

    def unlock(password)
      wallet_required!
      rpc(:password_enter, password: password)[:valid] == 1
    end

    def change_password(password)
      wallet_required!
      rpc(:password_change, password: password)[:changed] == 1
    end

    def all
      wallet_required!
      rpc(:account_list)[:accounts]
    end

    private

    def rpc(action, params={})
      p = @wallet.nil? ? {} : { wallet: @wallet }
      @rpc.call(action, p.merge(params))
    end

    def wallet_required!
      if @wallet.nil?
        raise ArgumentError.new("Wallet must be present")
      end
    end

    def validate_wallet_contains_account!(account)
      @known_valid_accounts ||= []
      return if @known_valid_accounts.include?(account)

      if contains?(account)
        @known_valid_accounts << account
      else
        raise ArgumentError.new("Account does not exist in wallet. Account: #{account}, wallet: #{@wallet}")
      end
    end

  end
end
