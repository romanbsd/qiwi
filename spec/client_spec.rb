require 'spec_helper'
require 'qiwi/client'

describe Qiwi::Client do
  let(:client) { Qiwi::Client.new('login', 'pass', 'http://localhost:8088/mock') }
  let(:create_bill) do
    lambda { client.create_bill(user: 'user_id', amount: 1000, comment: 'comment', txn: 'txn') }
  end

  context "Valid request" do

    it "sends login and password" do
      blk = lambda do |req|
        expect(req.body).to match(%r{<login>\w+</login>})
        expect(req.body).to match(%r{<password>\w+</password>})
      end
      stub_request(:post, "http://localhost:8088/mock").with(&blk).
        to_return(:status => 200, :body => '')
      create_bill.call
    end

    it "performs create_bill" do
      body = <<-EOF
      <soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope" xmlns:ser="http://server.ishop.mw.ru/">
         <soap:Header/>
         <soap:Body>
            <ser:createBillResponse>
               <createBillResult>0</createBillResult>
            </ser:createBillResponse>
         </soap:Body>
      </soap:Envelope>
      EOF
      stub_request(:post, "http://localhost:8088/mock").
        to_return(:status => 200, :body => body)

      result = create_bill.call
      expect(result).to eq(0)
    end

    it "performs cancel bill" do
      body = <<-EOF
      <soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope">
         <soap:Body>
            <ns2:cancelBillResponse xmlns:ns2="http://server.ishop.mw.ru/">
               <cancelBillResult>300</cancelBillResult>
            </ns2:cancelBillResponse>
         </soap:Body>
      </soap:Envelope>
      EOF
      stub_request(:post, "http://localhost:8088/mock").
        to_return(:status => 200, :body => body)

      result = client.cancel_bill(user: 'user', amount: 1000, comment: 'comment', txn: 'txn')
      expect(result).to eq(300)
    end
  end

  context "Errors" do
    it "handles SOAP errors" do
      body = <<-EOF
      <soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope">
        <soap:Body>
          <soap:Fault>
            <soap:Code>
              <soap:Value>soap:Sender</soap:Value>
            </soap:Code>
            <soap:Reason>
              <soap:Text xml:lang="en">Unmarshalling Error: unexpected element (uri:"http://server.ishop.mw.ru/", local:"login"). Expected elements are &lt;{}amount>,&lt;{}alarm>,&lt;{}lifetime>,&lt;{}txn>,&lt;{}login>,&lt;{}comment>,&lt;{}create>,&lt;{}user>,&lt;{}password>
              </soap:Text>
            </soap:Reason>
          </soap:Fault>
        </soap:Body>
      </soap:Envelope>
      EOF
      stub_request(:post, "http://localhost:8088/mock").
        to_return(:status => 500, :body => body)

      expect { create_bill.call }.to raise_error(Qiwi::SOAPError)
    end

    it "handles HTTP errors" do
      stub_request(:post, "http://localhost:8088/mock").
        to_return(:status => 500, :body => 'body')

      expect { create_bill.call }.to raise_error(Qiwi::ServerError)
    end
  end

  context "Configuration" do
    it "requires login and password" do
      expect { Qiwi::Client.new }.to raise_error(ArgumentError)
    end

    it "configures the client" do
      Qiwi.configure do |config|
        config.login = 'mylogin'
        config.password = 'mypassword'
      end
      client = Qiwi::Client.new
      expect(client.login).to eq('mylogin')
      expect(client.password).to eq('mypassword')
      expect(client.endpoint).to eq(Qiwi::Client::ENDPOINT)
    end

  end

end
