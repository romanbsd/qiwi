require 'ostruct'
require 'active_model/validations'

module Qiwi
  module Request

    class Base
      include ActiveModel::Validations

      def self.inherited(klass)
        klass.attributes :login, :password
        klass.validates_presence_of :login, :password
      end

      def self.attributes(*attrs)
        if attrs.empty?
          @_attributes
        else
          @_attributes ||= []
          @_attributes += attrs
          attr_accessor(*attrs)
        end
      end

      # See concrete classes for parameters description.
      #
      # @param [Qiwi::Client] client
      # @param [Hash] params
      def initialize(client, params)
        self.class.attributes.each { |attr| send(:"#{attr}=", params[attr]) }
        @login ||= client.login
        @password ||= client.password
      end

      def body
        with_envelope { |xml| soap_body(xml) }
      end

      def with_envelope(&block)
        Nokogiri::XML::Builder.new do |xml|
          xml.Envelope("xmlns:soapenv" => "http://www.w3.org/2003/05/soap-envelope",
                       "xmlns:tns" => "http://server.ishop.mw.ru/") do
            xml.parent.namespace = xml.parent.namespace_definitions.first
            xml.Header
            xml.Body(&block)
          end
        end
      end

      def soap_body(xml)
        xml['tns'].send(method) do
          self.class.attributes.each do |attr|
            # Underscore, so 'comment' is used as a parameter
            # some ugly way to remove the namespace
            xml.send("#{attr}_", send(attr)).instance_variable_get(:@node).namespace = nil
          end
        end
      end

      # The SOAP method name
      def method
        @method ||= self.class.to_s.split('::').last.camelize(:lower)
      end

      # Make sense of what is returned by the server
      #
      # @param [Nokogiri::XML::Document] xml
      def result_from_xml(xml)
        xml.xpath("//#{method}Response/#{method}Result").text.to_i
      end
    end

    class CreateBill < Base
      attributes :user, :amount, :comment, :txn, :lifetime, :alarm, :create

      validates_presence_of :user, :amount, :txn
      validates_numericality_of :amount
      validates_length_of :comment, :maximum => 255
      validates_length_of :txn, :maximum => 30
      validates_format_of :lifetime, :with => /^\d{2}\.\d{2}\.\d{4}\s\d{2}:\d{2}:\d{2}$/, :allow_nil => true
      validates_inclusion_of :create, :in => [true, false]

      # @param [Hash] params
      # @option params [String] :user e.g. a phone number
      # @option params [Float] :amount
      # @option params [String] :comment
      # @option params [String] :txn unique bill identifier
      # @option params [String, Time] :lifetime in "dd.MM.yyyy HH:mm:ss" format
      # @option params [Fixnum] :alarm
      # @option params [Boolean] :create
      def initialize(client, params)
        super
        @alarm ||= 0
        @create = true if @create.nil?
        @lifetime = @lifetime.strftime('%d.%m.%Y %H:%M:%S') if @lifetime.respond_to?(:strftime)
      end
    end

    class CancelBill < Base
      attributes :txn
    end

    class CheckBill < Base
      attributes :txn

      # @example
      #   {:user=>"name", :amount=>1000.0, :date=>"07.09.2012 13:33", :status=>60}
      def result_from_xml(xml)
        el = xml.xpath("//checkBillResponse")
        OpenStruct.new({
          user: el.at('user').text,
          amount: el.at('amount').text.to_f,
          date: el.at('date').text,
          lifetime: el.at('lifetime').text,
          status: el.at('status').text.to_i
        })
      end
    end

    class GetBillList < Base
      attributes :dateFrom, :dateTo, :status

      validates_presence_of :status
      validates_numericality_of :status

      # @param [Hash] params
      # @option params [String] :user e.g. a phone number
      # @option params [Time] :date_from
      # @option params [Time] :date_to
      # @option params [Fixnum] :status
      def initialize(client, params)
        super
        @dateFrom = params[:date_from].strftime('%d.%m.%Y %H:%M:%S') if params[:date_from]
        @dateTo = params[:date_to].strftime('%d.%m.%Y %H:%M:%S') if params[:date_to]
      end

      def result_from_xml(xml)
        el = xml.xpath("//getBillListResponse")
        OpenStruct.new({
          txns: el.at('txns').text,
          count: el.at('count').text.to_i
        })
      end
    end
  end
end
