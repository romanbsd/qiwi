require 'nokogiri'
require 'digest/md5'
require 'qiwi/handler'

module Qiwi
  class Server
    attr_accessor :handler

    # Creates a new instance of Rack application
    #
    # @param [String] login
    # @param [String] password
    # @param [Proc] handler must return 0 on success
    def initialize(login = nil, password = nil, handler = nil)
      @login = login || Qiwi.config.login
      @password = password || Qiwi.config.password
      @handler = handler || Qiwi::Handler
    end

    def call(env)
      @logger = env['rack.logger']

      if env['QUERY_STRING'] == 'wsdl'
        body = File.read(File.join(File.dirname(__FILE__), 'IShopClientWS.wsdl'))
      else
        body = env['rack.input'].read
        result = handle_soap_body(body)
        body = <<-EOF
<soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope" xmlns:cli="http://client.ishop.mw.ru/">
   <soap:Body>
      <cli:updateBillResponse>
         <updateBillResult>#{result}</updateBillResult>
      </cli:updateBillResponse>
   </soap:Body>
</soap:Envelope>
      EOF
      end
      headers = {'Content-Type' => 'application/soap+xml', 'Cache-Control' => 'no-cache'}
      [200, headers, [body]]
    end

    private
    def handle_soap_body(body)
      xml = Nokogiri::XML(body).remove_namespaces!
      nodeset = xml.xpath('//updateBill')
      return 300 if nodeset.empty?

      params = %w[login password txn status].each_with_object({}) do |field, h|
        h[field.to_sym] = nodeset.at(field).text
      end

      unless authorized?(params)
        logger.info "Unauthorized: #{params.inspect}"
        return 150
      end

      txn, status = params.values_at(:txn, :status)
      handler.call(txn, status.to_i).tap do |res|
        logger.info "Qiwi handler returned #{res}"
      end
    rescue => e
      # Unknown error
      logger.error "Error: #{e.message}\n#{e.backtrace.slice(0,2).join("\n")}"
      return 300
    end

    # Check if the password matches
    def authorized?(params)
      params[:login] == @login and
      params[:password] == Digest::MD5.hexdigest(params[:txn] + Digest::MD5.hexdigest(@password).upcase).upcase
    end

    def logger
      @logger ||= Logger.new(STDERR)
    end

  end
end
