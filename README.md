# qiwi

A framework for integration with the Qiwi payments platform.

You just need to provide the authentication details and transaction handler in you configuration,
and you're set.
For example, in Rails that would go into config/initializers/qiwi.rb:

```ruby
Qiwi.configure do |config|
  config.login = 'mylogin'
  config.password = 'secret'
  config.logger = Rails.logger
  config.transaction_handler = lambda do |txn|
    # The finder should respond to :find_by_txn, maybe an ActiveRecord model
    txn.finder = PendingTransaction
    # Observers that will be notified when the transaction is committed.
    # See Observable
    txn.add_observer(PendingTransaction, :commit_transaction)
    txn.add_observer(TransactionMailer, :transaction)
  end
end
```

Example commit_transaction implementation:

```ruby
class PendingTransaction < ActiveRecord::Base
  # @param [Qiwi::Transaction] txn
  def self.commit_transaction(txn)
    if txn.valid?
      if txn.to_sym == :paid
        txn.persisted.update_attribute(:approved, true)
      else
        # Notify user by e-mail
      end
    else
      # Log error, notify user by e-mail
    end
  # Rescue from exceptions, so other observers will still get an update
  rescue => e
    logger.error e.message
  end
end
```

It exposes the /qiwi endpoint which can be consumed by the Qiwi service.

Calling the Qiwi service is as simple as:

```ruby
client = Qiwi::Client.new
# See Qiwi::Request::CreateBill#initialize for all the parameters
client.create_bill(user: 'user', amount: 1000.0, comment: 'comment', txn: 'txnid')
client.check_bill(txn: 'txnid')
client.cancel_bill(txn: 'txnid')
client.get_bill_list(date_from: Time.now - 1209600, date_to: Time.now, status: 50)
```

## Contributing to qiwi
 
* Check out the latest master to make sure the feature hasn't been implemented or the bug hasn't been fixed yet.
* Check out the issue tracker to make sure someone already hasn't requested it and/or contributed it.
* Fork the project.
* Start a feature/bugfix branch.
* Commit and push until you are happy with your contribution.
* Make sure to add tests for it. This is important so I don't break it in a future version unintentionally.
* Please try not to mess with the Rakefile, version, or history. If you want to have your own version, or is otherwise necessary, that is fine, but please isolate to its own commit so I can cherry-pick around it.

## Copyright

Copyright (c) 2012 Roman Shterenzon. See LICENSE.txt for
further details.
