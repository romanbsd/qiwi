require 'qiwi/transaction'

module Qiwi
  class Handler
    def self.call(txn, status)
      new(txn, status).handle
    end

    attr_reader :txn
    def initialize(txn, status)
      @txn = Transaction.new(txn, status)
    end

    def handle
      check_transaction
    end

    def check_transaction
      unless txn.exists?
        logger.error "Transaction doesn't exist: #{txn.txn}"
        return 210
      end

      unless txn.valid_amount?
        logger.error "Incorrect amount: #{txn.amount}"
        return 241
      end

      if txn.valid?
        return  0
      else
        logger.error "Invalid transaction: #{txn.errors.full_messages.join(', ')}"
        return 300
      end

    rescue => e
      logger.fatal "Error: #{e.message}"
      return 300
    ensure
      txn.commit!
    end

    def logger
      Qiwi.logger
    end
  end
end
