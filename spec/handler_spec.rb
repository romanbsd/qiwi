require 'spec_helper'
require 'qiwi/handler'

describe Qiwi::Handler do
  let(:handler) { Qiwi::Handler.new('txnid', 60) }
  let(:txn) {
    double(:txn, :remote_status => 60, :exists? => true, :valid_amount? => true).as_null_object
  }

  before do
    allow(handler).to receive(:txn) { txn }
  end

  it "return 0 for valid transaction" do
    expect(handler.handle).to eq(0)
  end

  it "checks for existence of transaction" do
    allow(txn).to receive(:exists?) { false }
    expect(handler.handle).to eq(210)
  end

  it "checks amount" do
    allow(txn).to receive(:valid_amount?) { false }
    expect(handler.handle).to eq(241)
  end

  it "checks for unknown errors" do
    allow(txn).to receive(:valid?) { false }
    expect(handler.handle).to eq(300)
  end

end
