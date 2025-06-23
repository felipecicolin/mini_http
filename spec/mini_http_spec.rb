# frozen_string_literal: true

require "webmock/rspec"

RSpec.describe MiniHttp do
  before do
    WebMock.enable!
  end

  after do
    WebMock.reset!
  end

  it "has a version number" do
    expect(MiniHttp::VERSION).not_to be nil
  end

  describe ".get" do
    it "makes a GET request and returns a Response object" do
      stub_request(:get, "https://example.com/api")
        .to_return(status: 200, body: '{"success": true}', headers: { "Content-Type" => "application/json" })

      response = MiniHttp.get("https://example.com/api")

      expect(response).to be_a(MiniHttp::Response)
      expect(response.success?).to be true
      expect(response.code).to eq(200)
      expect(response.json).to eq({ "success" => true })
    end

    it "makes a GET request with custom headers" do
      stub_request(:get, "https://example.com/api")
        .with(headers: { "Authorization" => "Bearer token123", "User-Agent" => "MyApp/1.0" })
        .to_return(status: 200, body: "OK")

      response = MiniHttp.get("https://example.com/api",
                                headers: { "Authorization" => "Bearer token123", "User-Agent" => "MyApp/1.0" })

      expect(response.success?).to be true
    end

    it "makes a GET request with custom timeout" do
      stub_request(:get, "https://example.com/api")
        .to_return(status: 200, body: "OK")

      response = MiniHttp.get("https://example.com/api", timeout: 60)

      expect(response.success?).to be true
    end

    it "handles HTTP URLs" do
      stub_request(:get, "http://example.com/api")
        .to_return(status: 200, body: "OK")

      response = MiniHttp.get("http://example.com/api")

      expect(response.success?).to be true
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

      response = MiniHttp.post("https://example.com/api", body: { name: "John" })

      expect(response.success?).to be true
      expect(response.code).to eq(201)
      expect(response.json).to eq({ "id" => 1, "name" => "John" })
    end

    it "makes a POST request with string body" do
      stub_request(:post, "https://example.com/api")
        .with(
          body: "raw string data",
          headers: { "Content-Type" => "application/json" }
        )
        .to_return(status: 201, body: "Created")

      response = MiniHttp.post("https://example.com/api", body: "raw string data")

      expect(response.success?).to be true
    end

    it "makes a POST request without body" do
      stub_request(:post, "https://example.com/api")
        .to_return(status: 201, body: "Created")

      response = MiniHttp.post("https://example.com/api")

      expect(response.success?).to be true
    end

    it "makes a POST request with custom headers and preserves Content-Type" do
      stub_request(:post, "https://example.com/api")
        .with(
          body: '{"data":"test"}',
          headers: { "Content-Type" => "application/custom", "Authorization" => "Bearer token" }
        )
        .to_return(status: 201, body: "Created")

      response = MiniHttp.post("https://example.com/api",
                                 body: { data: "test" },
                                 headers: { "Content-Type" => "application/custom", "Authorization" => "Bearer token" })

      expect(response.success?).to be true
    end
  end

  describe ".put" do
    it "makes a PUT request" do
      stub_request(:put, "https://example.com/api/1")
        .to_return(status: 200, body: "OK")

      response = MiniHttp.put("https://example.com/api/1", body: { name: "Updated" })

      expect(response.success?).to be true
      expect(response.code).to eq(200)
    end

    it "makes a PUT request with string body" do
      stub_request(:put, "https://example.com/api/1")
        .with(
          body: "updated data",
          headers: { "Content-Type" => "application/json" }
        )
        .to_return(status: 200, body: "Updated")

      response = MiniHttp.put("https://example.com/api/1", body: "updated data")

      expect(response.success?).to be true
    end
  end

  describe ".delete" do
    it "makes a DELETE request" do
      stub_request(:delete, "https://example.com/api/1")
        .to_return(status: 204, body: "")

      response = MiniHttp.delete("https://example.com/api/1")

      expect(response.success?).to be true
      expect(response.code).to eq(204)
    end

    it "makes a DELETE request with headers" do
      stub_request(:delete, "https://example.com/api/1")
        .with(headers: { "Authorization" => "Bearer token123" })
        .to_return(status: 204, body: "")

      response = MiniHttp.delete("https://example.com/api/1",
                                   headers: { "Authorization" => "Bearer token123" })

      expect(response.success?).to be true
    end
  end

  describe "error handling" do
    it "raises ArgumentError for unsupported HTTP method" do
      expect do
        MiniHttp.send(:make_request, :patch, "https://example.com")
      end.to raise_error(ArgumentError, "Unsupported HTTP method: patch")
    end

    it "handles network errors gracefully" do
      stub_request(:get, "https://example.com/api")
        .to_raise(Timeout::Error)

      expect do
        MiniHttp.get("https://example.com/api")
      end.to raise_error(Timeout::Error)
    end

    it "handles invalid URLs" do
      expect do
        MiniHttp.get("not-a-url")
      end.to raise_error(ArgumentError, "not an HTTP URI")
    end
  end

  describe MiniHttp::Response do
    let(:net_response) { double("Net::HTTPResponse") }

    before do
      allow(net_response).to receive(:code).and_return("200")
      allow(net_response).to receive(:body).and_return('{"test": true}')
      allow(net_response).to receive(:to_hash).and_return({ "content-type" => ["application/json"] })
    end

    let(:response) { MiniHttp::Response.new(net_response) }

    describe "#success?" do
      it "returns true for 2xx status codes" do
        expect(response.success?).to be true
      end

      it "returns false for non-2xx status codes" do
        allow(net_response).to receive(:code).and_return("404")
        response = MiniHttp::Response.new(net_response)
        expect(response.success?).to be false
      end

      it "returns true for all 2xx codes" do
        (200..299).each do |code|
          allow(net_response).to receive(:code).and_return(code.to_s)
          response = MiniHttp::Response.new(net_response)
          expect(response.success?).to be true
        end
      end
    end

    describe "#client_error?" do
      it "returns true for 4xx status codes" do
        allow(net_response).to receive(:code).and_return("404")
        response = MiniHttp::Response.new(net_response)
        expect(response.client_error?).to be true
      end

      it "returns false for non-4xx status codes" do
        allow(net_response).to receive(:code).and_return("500")
        response = MiniHttp::Response.new(net_response)
        expect(response.client_error?).to be false
      end

      it "returns true for all 4xx codes" do
        [400, 401, 403, 404, 422, 429, 499].each do |code|
          allow(net_response).to receive(:code).and_return(code.to_s)
          response = MiniHttp::Response.new(net_response)
          expect(response.client_error?).to be true
        end
      end
    end

    describe "#server_error?" do
      it "returns true for 5xx status codes" do
        allow(net_response).to receive(:code).and_return("500")
        response = MiniHttp::Response.new(net_response)
        expect(response.server_error?).to be true
      end

      it "returns false for non-5xx status codes" do
        allow(net_response).to receive(:code).and_return("404")
        response = MiniHttp::Response.new(net_response)
        expect(response.server_error?).to be false
      end

      it "returns true for all 5xx codes" do
        [500, 501, 502, 503, 504, 599].each do |code|
          allow(net_response).to receive(:code).and_return(code.to_s)
          response = MiniHttp::Response.new(net_response)
          expect(response.server_error?).to be true
        end
      end
    end

    describe "#json" do
      it "parses JSON response" do
        expect(response.json).to eq({ "test" => true })
      end

      it "returns nil for invalid JSON" do
        allow(net_response).to receive(:body).and_return("invalid json")
        response = MiniHttp::Response.new(net_response)
        expect(response.json).to be_nil
      end

      it "caches parsed JSON" do
        expect(JSON).to receive(:parse).once.and_return({ "cached" => true })

        2.times { response.json }
      end

      it "handles empty response body" do
        allow(net_response).to receive(:body).and_return("")
        response = MiniHttp::Response.new(net_response)
        expect(response.json).to be_nil
      end

      it "handles nil response body" do
        allow(net_response).to receive(:body).and_return(nil)
        response = MiniHttp::Response.new(net_response)
        expect(response.json).to be_nil
      end

      it "parses JSON arrays" do
        allow(net_response).to receive(:body).and_return('[{"id": 1}, {"id": 2}]')
        response = MiniHttp::Response.new(net_response)
        expect(response.json).to eq([{ "id" => 1 }, { "id" => 2 }])
      end
    end

    describe "#code" do
      it "converts string status code to integer" do
        allow(net_response).to receive(:code).and_return("404")
        response = MiniHttp::Response.new(net_response)
        expect(response.code).to eq(404)
        expect(response.code).to be_a(Integer)
      end
    end

    describe "#body" do
      it "returns the response body as string" do
        expect(response.body).to eq('{"test": true}')
      end
    end

    describe "#headers" do
      it "returns the response headers hash" do
        expect(response.headers).to eq({ "content-type" => ["application/json"] })
      end
    end
  end
end
