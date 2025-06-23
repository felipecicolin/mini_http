# MiniHttp

A minimal, lightweight HTTP client library for Ruby that provides a clean interface for making HTTP requests withBug reports and pull requests are welcome on GitHub at https://github.com/felipecicolin/mini_http. This project is intended to be a safe, welcoming space for collaboration.automatic JSON handling, SSL support, and customizable timeouts.

## Features

- Simple API for GET, POST, PUT, and DELETE requests
- Automatic JSON parsing and serialization
- SSL/HTTPS support with proper certificate verification
- Configurable timeouts
- Response helper methods for status checking
- No external dependencies beyond Ruby standard library

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'mini_http'
```

And then execute:

```bash
bundle install
```

Or install it yourself as:

```bash
gem install mini_http
```

## Usage

### Basic GET request

```ruby
response = MiniHttp.get("https://api.example.com/users")

if response.success?
  users = response.json
  puts users
else
  puts "Error: #{response.code}"
end
```

### POST request with JSON body

```ruby
response = MiniHttp.post(
  "https://api.example.com/users",
  body: { name: "John", email: "john@example.com" },
  headers: { "Authorization" => "Bearer token123" }
)

if response.success?
  puts "User created: #{response.json}"
end
```

### PUT request

```ruby
response = MiniHttp.put(
  "https://api.example.com/users/1",
  body: { name: "John Updated" },
  timeout: 60
)
```

### DELETE request

```ruby
response = MiniHttp.delete(
  "https://api.example.com/users/1",
  headers: { "Authorization" => "Bearer token123" }
)
```

### Response methods

```ruby
response = MiniHttp.get("https://api.example.com/data")

# Status checking
response.success?       # true for 2xx status codes
response.client_error?  # true for 4xx status codes
response.server_error?  # true for 5xx status codes

# Response data
response.code           # HTTP status code (integer)
response.body           # Raw response body (string)
response.headers        # Response headers (hash)
response.json           # Parsed JSON (hash/array, nil if not valid JSON)
```

### Customizing requests

All methods support these optional parameters:

- `headers`: Hash of HTTP headers
- `timeout`: Request timeout in seconds (default: 30)
- `body`: Request body for POST/PUT (string or object that responds to `to_json`)

```ruby
response = MiniHttp.get(
  "https://api.example.com/data",
  headers: {
    "User-Agent" => "MyApp/1.0",
    "Accept" => "application/json"
  },
  timeout: 45
)
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/felipecicolin/simple_http. This project is intended to be a safe, welcoming space for collaboration.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
