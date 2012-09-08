require 'spec_helper'
require 'qiwi/request'

describe Qiwi::Request do

  describe 'CreateBill' do

    it "is invalid" do
      subject = Qiwi::Request::CreateBill.new(mock.as_null_object, {})
      subject.should_not be_valid
    end

    it "has all attributes" do
      Qiwi::Request::CreateBill.attributes.should eq([:login, :password, :user, :amount, :comment, :txn, :lifetime, :alarm, :create])
    end

  end

  describe 'GetBillList' do
    it "converts dates" do
      req = Qiwi::Request::GetBillList.new(mock.as_null_object, {date_from: Time.now - 86400, date_to: Time.now})
      req.dateFrom.should match(/\d{2}\.\d{2}\.\d{4}\s\d{2}:\d{2}:\d{2}/)
      req.dateTo.should match(/\d{2}\.\d{2}\.\d{4}\s\d{2}:\d{2}:\d{2}/)
    end
  end
end
