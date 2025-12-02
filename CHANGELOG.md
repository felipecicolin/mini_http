## [0.1.1] - 2025-12-02

### Added
- SSL verification can now be disabled in development/test environments via DISABLE_SSL_VERIFY=true environment variable
- Automatic SSL verification in production environments (RAILS_ENV=production or RACK_ENV=production)

## [Unreleased]

## [0.1.0] - 2025-06-23

- Initial release of MiniHttp
- Support for GET, POST, PUT, DELETE requests  
- Automatic JSON parsing and serialization
- SSL/HTTPS support with proper certificate verification
- Configurable timeouts
- Response helper methods for status checking
- No external dependencies beyond Ruby standard library
