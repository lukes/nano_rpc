class Nanook
  class Account

    def initialize(account, rpc)
      @account = account
      @rpc = rpc
    end

    def history(limit: 1000)
      account_required!
      rpc(:account_history, count: limit)
    end

    def key
      account_required!
      rpc(:account_key)
    end

    def representative
      account_required!
      rpc(:account_representative)
    end

    private

    def rpc(action, params={})
      p = @account.nil? ? {} : { account: @account }
      @rpc.call(action, p.merge(params))
    end

    def account_required!
      if @account.nil?
        raise ArgumentError.new("Account must be present")
      end
    end

  end
end
