require 'spec_helper'
require 'qiwi/handler'

describe Qiwi::Handler do
  let(:handler) { Qiwi::Handler.new('txnid', 60) }
  let(:txn) {
    mock(:txn, :remote_status => 60, :exists? => true, :valid_amount? => true).as_null_object
  }

  before do
    handler.stub(:txn) { txn }
  end

  it "return 0 for valid transaction" do
    handler.handle.should eq(0)
  end

  it "checks for matching status" do
    txn.stub(:remote_status) { 50 }
    handler.handle.should eq(300)
  end

  it "checks for existence of transaction" do
    txn.stub(:exists?) { false }
    handler.handle.should eq(210)
  end

  it "checks amount" do
    txn.stub(:valid_amount?) { false }
    handler.handle.should eq(241)
  end

  it "checks for unknown errors" do
    txn.stub(:valid?) { false }
    handler.handle.should eq(300)
  end

end
