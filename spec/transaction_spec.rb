require 'spec_helper'
require 'qiwi/client'
require 'qiwi/transaction'

describe Qiwi::Transaction do
  before :all do
    Qiwi.configure do |config|
      config.login = 'login'
      config.password = 'password'
    end
  end

  before do
    Qiwi::Client.any_instance.stub(:check_bill).and_return OpenStruct.new({
      :user=>"name", :amount=>1000.0, :date=>"07.09.2012 13:33", :status=>60
    })
  end

  describe "Validations" do
    it "checks amount" do
      persisted = mock(:txn, :amount => 2000.0)
      finder = mock(:finder, :find_by_txn => persisted)
      txn = Qiwi::Transaction.new('txid') { |tx| tx.finder = finder }
      txn.should_not be_valid_amount
    end
  end

  describe "Observable" do
    class MockObserver
      def update(txn)
      end
    end

    it "notifies observers" do
      observer = MockObserver.new
      txn = Qiwi::Transaction.new('txid') { |tx| tx.add_observer(observer) }
      observer.should_receive(:update).with(txn)
      txn.commit!
    end
  end
end
