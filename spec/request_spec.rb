require 'spec_helper'
require 'qiwi/request'

describe Qiwi::Request do

  describe 'CreateBill' do

    it "is invalid" do
      subject = Qiwi::Request::CreateBill.new(double.as_null_object, {})
      expect(subject).not_to be_valid
    end

    it "has all attributes" do
      expect(Qiwi::Request::CreateBill.attributes).to eq([:login, :password, :user, :amount, :comment, :txn, :lifetime, :alarm, :create])
    end

    it "allows time as a lifetime" do
      lifetime = Time.now + 86400
      r = Qiwi::Request::CreateBill.new(double.as_null_object, lifetime: lifetime)
      expect(r.lifetime).to be_a_kind_of(String)
      expect(r.lifetime).to eq(lifetime.strftime("%d.%m.%Y %H:%M:%S"))
    end

    it "only allows boolean as 'create'" do
      r = Qiwi::Request::CreateBill.new(double.as_null_object, create: 1)
      expect(r).not_to be_valid
      expect(r.errors[:create].size).to eq(1)
    end

    it "validates all parameters" do
      r = Qiwi::Request::CreateBill.new(double.as_null_object, {
        login: 'login',
        password: 'password',
        user: 'user',
        amount: 900,
        txn: 'txnid',
        create: false
      })
      expect(r).to be_valid
    end
  end

  describe 'GetBillList' do
    it "converts dates" do
      req = Qiwi::Request::GetBillList.new(double.as_null_object, {date_from: Time.now - 86400, date_to: Time.now})
      expect(req.dateFrom).to match(/\d{2}\.\d{2}\.\d{4}\s\d{2}:\d{2}:\d{2}/)
      expect(req.dateTo).to match(/\d{2}\.\d{2}\.\d{4}\s\d{2}:\d{2}:\d{2}/)
    end
  end
end
