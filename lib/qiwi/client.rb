require 'active_support/core_ext/string/inflections'
require 'active_model'
require 'nokogiri'
require 'faraday'
require 'qiwi/config'
require 'qiwi/request'

module Qiwi

  class Client
    ENDPOINT = 'https://ishop.qiwi.ru/services/ishop'.freeze
    HEADERS = {'Content-Type' => 'text/xml; charset=utf-8'}.freeze

    attr_reader :login, :password, :endpoint
    def initialize(login = nil, password = nil, endpoint = nil)
      @login = login || Qiwi.config.login
      @password = password || Qiwi.config.password
      @endpoint = endpoint || Qiwi.config.endpoint || ENDPOINT
      raise ArgumentError.new("Missing login or password") unless @login and @password
    end

    [:create_bill, :cancel_bill, :check_bill, :get_bill_list].each do |method|
      class_eval <<-EOF, __FILE__, __LINE__ + 1
        def #{method}(params)
          request = Request::#{method.to_s.classify}.new(self, params)
          if request.valid?
            perform(request)
          else
            raise InvalidRequestError.new(request.errors)
          end
        end
      EOF
    end

    # Advanced methods
    # :create_bill_ccy
    # :cancel_bill_payed_amount
    # :create_bill_ext

    private

    def perform(request)
      body = request.body
      conn = Faraday.new
      response = conn.post(@endpoint, body.to_xml, HEADERS)
      unless response.success?
        handle_error(response)
        return
      end
      xml = Nokogiri::XML(response.body).remove_namespaces!
      request.result_from_xml(xml)
    # rescue
    #   raise ServerError.new(response)
    end

    def handle_error(response)
      el = nil
      begin
        xml = Nokogiri::XML(response.body)
        xpath = '/soapenv:Envelope/soapenv:Body/soapenv:Fault'
        el = xml.xpath(xpath)
      rescue
        # If it's not an XML response
        raise ServerError.new(response)
      end

      code = el.at('faultcode').text
      string = el.at('faultstring').text
      raise SOAPError.new(code, string)
    end

  end


  class SOAPError < StandardError
    attr_reader :code
    def initialize(code, string)
      @code = code
      super(string)
    end
  end

  class InvalidRequestError < StandardError
    # @param [ActiveModel::Errors] errors
    def initialize(errors)
      super(errors.full_messages.join("\n"))
    end
  end

  class ServerError < StandardError
    attr_reader :response
    def initialize(response)
      super(response.body)
    end
  end

end

if $0 == __FILE__
  client = Qiwi::Client.new('test', 'pass', 'http://localhost:8088/mock')
  puts client.create_bill(user: 'user', amount: 1000, comment: 'comment', txn: 'txn').inspect
  puts client.cancel_bill(txn: 'txn').inspect
  puts client.check_bill(txn: 'txn').inspect
  puts client.get_bill_list(date_from: Time.now - 1209600, date_to: Time.now, status: 50)
end
