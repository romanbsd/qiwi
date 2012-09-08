# qiwi

A framework for integration with the Qiwi payments platform.

You just need to provide a transaction handler in you configuration, and you're set.
For example, in Rails it would be config/initializers/qiwi.rb

    Qiwi.configure do |config|
      config.login = 'mylogin'
      config.password = 'secret'
      config.logger = Rails.logger
      config.transaction_handler = lambda do |txn|
        # finder should respond to :find_by_txn
        txn.finder = PendingTransactions
        txn.add_observer(PendingTransactions, :commit_transaction)
        txn.add_observer(TransactionMailer, :transaction)
      end
    end

It exposes the /qiwi endpoint which can be consumed by Qiwi service.

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

