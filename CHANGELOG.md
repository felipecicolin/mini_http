## [Unreleased]

## [0.2.0] - 2025-12-02

### Added
- Added `ssl` option to disable SSL certificate verification for development environments
- SSL verification can now be disabled by passing `ssl: false` to any HTTP method

### Changed
- Refactored parameter handling to use keyword arguments splat (`**options`) to comply with RuboCop metrics
- Improved code maintainability by reducing parameter count in method signatures

### Fixed
- Fixed RuboCop Metrics/ParameterLists violation

## [0.1.0] - 2025-06-23

- Initial release of MiniHttp
- Support for GET, POST, PUT, DELETE requests  
- Automatic JSON parsing and serialization
- SSL/HTTPS support with proper certificate verification
- Configurable timeouts
- Response helper methods for status checking
- No external dependencies beyond Ruby standard library
