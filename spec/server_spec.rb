require 'spec_helper'
require 'qiwi/server'
require 'rack/mock'

describe Qiwi::Server do
  let(:app) { Qiwi::Server.new('login', 'password') }
  let(:request) { Rack::MockRequest.new(app) }

  def request_body(params = {})
    <<-EOF
    <soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope" xmlns:cli="http://client.ishop.mw.ru/">
       <soap:Header/>
       <soap:Body>
          <cli:updateBill>
             <login>#{params[:login] || 'login'}</login>
             <password>#{params[:password] || '9D404B747E58461E01A0584DD774C4DB'}</password>
             <txn>#{params[:txn] || 'valid_txn'}</txn>
             <status>#{params[:status] || 60}</status>
          </cli:updateBill>
       </soap:Body>
    </soap:Envelope>
    EOF
  end

  def result(response)
    response.body[%r{<updateBillResult>(\d+)</updateBillResult>}, 1].to_i
  end

  def perform(request, body)
    request.post('/', lint: true, input: body)
  end

  context "Valid request" do
    it "handles 'paid' callbacks" do
      app.handler = lambda do |txn, status|
        expect(txn).to eq('valid_txn')
        expect(status).to eq(60)
        return 0
      end

      response = perform(request, request_body)
      expect(result(response)).to eq(0)
    end

    it "passes results from callback" do
      app.handler = proc { 210 }
      response = perform(request, request_body)
      expect(result(response)).to eq(210)
    end
  end

  context "Invalid request" do
    it "returns 300" do
      response = perform(request, '<invalid/>')
      expect(result(response)).to eq(300)
    end

    it "returns 300 on missing parameters" do
      response = perform(request, '<updateBill></updateBill>')
      expect(result(response)).to eq(300)
    end
  end

  context "Wrong auth" do
    it "handles wrong password" do
      response = perform(request, request_body(password: 'wrong'))
      expect(result(response)).to eq(150)
    end

    it "handles wrong login" do
      response = perform(request, request_body(login: 'wrong'))
      expect(result(response)).to eq(150)
    end
  end

  context "WSDL request" do
    it "returns wsdl" do
      response = request.get('/?wsdl', lint: true)
      expect(response.body).to include('wsdl:definitions')
    end
  end

end
