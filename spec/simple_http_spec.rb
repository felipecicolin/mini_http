# frozen_string_literal: true

require "webmock/rspec"

RSpec.describe SimpleHttp do
  before do
    WebMock.enable!
  end

  after do
    WebMock.reset!
  end

  it "has a version number" do
    expect(SimpleHttp::VERSION).not_to be nil
  end

  describe ".get" do
    it "makes a GET request and returns a Response object" do
      stub_request(:get, "https://example.com/api")
        .to_return(status: 200, body: '{"success": true}', headers: { "Content-Type" => "application/json" })

      response = SimpleHttp.get("https://example.com/api")

      expect(response).to be_a(SimpleHttp::Response)
      expect(response.success?).to be true
      expect(response.code).to eq(200)
      expect(response.json).to eq({ "success" => true })
    end
  end

  describe ".post" do
    it "makes a POST request with JSON body" do
      stub_request(:post, "https://example.com/api")
        .with(
          body: '{"name":"John"}',
          headers: { "Content-Type" => "application/json" }
        )
        .to_return(status: 201, body: '{"id": 1, "name": "John"}')

      response = SimpleHttp.post("https://example.com/api", body: { name: "John" })

      expect(response.success?).to be true
      expect(response.code).to eq(201)
      expect(response.json).to eq({ "id" => 1, "name" => "John" })
    end
  end

  describe ".put" do
    it "makes a PUT request" do
      stub_request(:put, "https://example.com/api/1")
        .to_return(status: 200, body: "OK")

      response = SimpleHttp.put("https://example.com/api/1", body: { name: "Updated" })

      expect(response.success?).to be true
      expect(response.code).to eq(200)
    end
  end

  describe ".delete" do
    it "makes a DELETE request" do
      stub_request(:delete, "https://example.com/api/1")
        .to_return(status: 204, body: "")

      response = SimpleHttp.delete("https://example.com/api/1")

      expect(response.success?).to be true
      expect(response.code).to eq(204)
    end
  end

  describe SimpleHttp::Response do
    let(:net_response) { double("Net::HTTPResponse") }

    before do
      allow(net_response).to receive(:code).and_return("200")
      allow(net_response).to receive(:body).and_return('{"test": true}')
      allow(net_response).to receive(:to_hash).and_return({ "content-type" => ["application/json"] })
    end

    let(:response) { SimpleHttp::Response.new(net_response) }

    describe "#success?" do
      it "returns true for 2xx status codes" do
        expect(response.success?).to be true
      end

      it "returns false for non-2xx status codes" do
        allow(net_response).to receive(:code).and_return("404")
        response = SimpleHttp::Response.new(net_response)
        expect(response.success?).to be false
      end
    end

    describe "#client_error?" do
      it "returns true for 4xx status codes" do
        allow(net_response).to receive(:code).and_return("404")
        response = SimpleHttp::Response.new(net_response)
        expect(response.client_error?).to be true
      end
    end

    describe "#server_error?" do
      it "returns true for 5xx status codes" do
        allow(net_response).to receive(:code).and_return("500")
        response = SimpleHttp::Response.new(net_response)
        expect(response.server_error?).to be true
      end
    end

    describe "#json" do
      it "parses JSON response" do
        expect(response.json).to eq({ "test" => true })
      end

      it "returns nil for invalid JSON" do
        allow(net_response).to receive(:body).and_return("invalid json")
        response = SimpleHttp::Response.new(net_response)
        expect(response.json).to be_nil
      end
    end
  end
end
