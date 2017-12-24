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
    allow_any_instance_of(Qiwi::Client).to receive(:check_bill).and_return OpenStruct.new({
      :user=>"name", :amount=>1000.0, :date=>"07.09.2012 13:33", :status=>60
    })
  end

  describe "Validations" do
    it "checks amount" do
      persisted = double(:txn, :amount => 2000.0)
      finder = double(:finder, :find_by_txn => persisted)
      txn = Qiwi::Transaction.new('txid', 60) { |tx| tx.finder = finder }
      expect(txn).not_to be_valid_amount
    end

    it "has error on status when it differs" do
      txn = Qiwi::Transaction.new('txid', 160) { |tx| tx.finder = nil }
      expect(txn).not_to be_valid
      expect(txn.errors[:status].size).to eq(1)
    end

    it "checks remote status" do
      txn = Qiwi::Transaction.new('txid', 60) { |tx| tx.finder = nil }
      txn.valid?
      expect(txn.errors[:status]).to be_empty
    end

  end

  describe "Observable" do
    class MockObserver
      def update(txn)
      end
    end

    it "notifies observers" do
      observer = MockObserver.new
      txn = Qiwi::Transaction.new('txid', 60) { |tx| tx.add_observer(observer) }
      expect(observer).to receive(:update).with(txn)
      txn.commit!
    end
  end
end
