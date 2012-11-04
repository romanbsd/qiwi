require 'qiwi/client'
require 'observer'
require 'active_model'
require 'active_support/core_ext/module/delegation'

module Qiwi
  class Transaction
    include Observable
    include ActiveModel::Validations

    class RemoteValidator < ActiveModel::EachValidator
      def validate_each(txn, attribute, value)
        unless txn.remote.send(attribute) == value
          txn.errors.add(attribute, :invalid)
        end
      end
    end

    validates_presence_of :txn
    validates_presence_of :persisted, :remote, :message => 'transaction not found'
    validates :amount, :numericality => true, :remote => true
    validates :status, :remote => true

    delegate :amount, :status, :to => :remote, :prefix => true, :allow_nil => true

    # Transaction id
    attr_reader :txn, :status

    # Finder should respond_to?(:find_by_txn) and return an object,
    # which can respond_to?(:amount)
    attr_accessor :finder

    def initialize(txn, status)
      @txn = txn
      @status = status

      # A logging observer
      add_observer(self, :log_transaction)

      if block_given?
        yield self
      else
        Qiwi.config.transaction_handler.call(self) if Qiwi.config.transaction_handler
      end
    end

    def inspect
      error_msgs = errors.full_messages.join(', ')
      %{<Qiwi::Transaction id: #{txn}, remote: #{remote.inspect} persisted: #{persisted.inspect} errors: #{error_msgs}}
    end

    def commit!
      changed
      notify_observers(self)
    end

    def exists?
      !!persisted
    end

    def valid_amount?
      valid?
      errors[:amount].empty?
    end

    def amount
      persisted.amount if exists?
    end

    def log_transaction(transaction)
      Qiwi.logger.info "Transaction update: #{transaction.inspect}"
    end

    def remote
      @remote ||= Qiwi::Client.new.check_bill(txn: txn)
    end

    def persisted
      @persisted ||= find(txn)
    end

    def find(txn)
      finder.find_by_txn(txn) if finder
    end

  end
end

# # Example:
# Qiwi.configure do |config|
#   config.transaction_handler = lambda do |txn|
#     txn.finder = PendingTransactions
#     txn.add_observer(TransactionHandler.new)
#   end
# end
