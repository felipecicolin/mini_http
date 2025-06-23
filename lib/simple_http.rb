# frozen_string_literal: true

require "net/http"
require "uri"
require "json"
require "openssl"
require_relative "simple_http/version"

class SimpleHttp
  class Response
    SUCCESS_RANGE = (200..299).freeze
    CLIENT_ERROR_RANGE = (400..499).freeze
    SERVER_ERROR_RANGE = (500..599).freeze

    attr_reader :code, :body, :headers

    def initialize(net_response)
      @code = extract_status_code(net_response)
      @body = net_response.body
      @headers = net_response.to_hash
    end

    def success?
      SUCCESS_RANGE.cover?(@code)
    end

    def client_error?
      CLIENT_ERROR_RANGE.cover?(@code)
    end

    def server_error?
      SERVER_ERROR_RANGE.cover?(@code)
    end

    def json
      @json ||= parse_json_safely
    end

    private

    def extract_status_code(net_response)
      net_response.code.to_i
    end

    def parse_json_safely
      return nil if @body.nil? || @body.empty?

      JSON.parse(@body)
    rescue JSON::ParserError
      nil
    end
  end

  def self.get(url, headers: {}, timeout: 30)
    make_request(:get, url, headers: headers, timeout: timeout)
  end

  def self.post(url, body: nil, headers: {}, timeout: 30)
    make_request(:post, url, body: body, headers: headers, timeout: timeout)
  end

  def self.put(url, body: nil, headers: {}, timeout: 30)
    make_request(:put, url, body: body, headers: headers, timeout: timeout)
  end

  def self.delete(url, headers: {}, timeout: 30)
    make_request(:delete, url, headers: headers, timeout: timeout)
  end

  class << self
    private

    def make_request(method, url, body: nil, headers: {}, timeout: 30)
      uri = URI(url)
      http = build_http_client(uri, timeout)
      request = build_request(method, uri, body, headers)

      net_response = http.request(request)
      Response.new(net_response)
    end

    def build_http_client(uri, timeout)
      http = Net::HTTP.new(uri.host, uri.port)
      configure_ssl(http, uri)
      configure_timeouts(http, timeout)
      http
    end

    def configure_ssl(http, uri)
      return unless uri.scheme == "https"

      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_PEER
    end

    def configure_timeouts(http, timeout)
      http.read_timeout = timeout
      http.open_timeout = [timeout / 3, 10].min
    end

    def build_request(method, uri, body, headers)
      request = create_request_object(method, uri)
      set_headers(request, headers)
      set_body(request, method, body)
      request
    end

    def create_request_object(method, uri)
      case method
      when :get
        Net::HTTP::Get.new(uri)
      when :post
        Net::HTTP::Post.new(uri)
      when :put
        Net::HTTP::Put.new(uri)
      when :delete
        Net::HTTP::Delete.new(uri)
      else
        raise ArgumentError, "Unsupported HTTP method: #{method}"
      end
    end

    def set_headers(request, headers)
      headers.each { |key, value| request[key] = value }
    end

    def set_body(request, method, body)
      return unless body && body_allowed?(method)

      request.body = serialize_body(body)
      request["Content-Type"] ||= "application/json"
    end

    def body_allowed?(method)
      %i[post put].include?(method)
    end

    def serialize_body(body)
      body.is_a?(String) ? body : body.to_json
    end
  end
end
