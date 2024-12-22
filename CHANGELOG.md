## [0.1.4] - 2024-12-20
- CI Improvements
    - Added annotations
    - Runs tests from ActiveResource
- Separated Collection caching logic into ActiveCachedResource::Collection as opposed to monkey patching ActiveResource::Collection
- Changed name of SQL adapter from `active_record` to `active_record_sql`
- Changed method name of ActiveCachedResource::Model from `clear` to `clear_cache`

## [0.1.3] - 2024-12-19
- Minor patch on ActiveResource. Removed deprecator log.

## [0.1.2] - 2024-12-19
- Minor patch on ActiveResource::Collection initializing attributes.

## [0.1.1] - 2024-12-17

- Added ruby yard documentation
- Added LICENSE
- Improved gemspec
- Changed name of ActiveSupport::Cache adapter from `active_support` to `active_support_cache`


## [0.1.0] - 2024-12-16

- Initial release
