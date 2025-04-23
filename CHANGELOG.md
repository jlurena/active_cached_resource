## [0.2.0] - 2024-04-25
- Allow virtual attributes to be persisted into cache with introduction of `ActiveCachedResource::Collection.persisted_attribute`.

## [0.1.10] - 2024-03-05
- Patch Collection#reload to return correct type

## [0.1.9] - 2024-02-05
- Fixed bug not allowing reloading collection cache
- Change debug to info for cache hits

## [0.1.8] - 2024-01-24
- Fixed issue with `#clear_cache` method with Redis

## [0.1.7] - 2024-01-23
- Improved `clear_cache` method for `active_support_cache` strategy to no longer use `delete_matched`.
- Introduced `.delete_from_cache` method to delete single cached resources.

## [0.1.6] - 2024-01-15
- Renamed `ActiveResource::Collection#refresh` to `#reload` to match Rails ORM naming convention.
- Added a `ActiveResource::Collection.none` class method similar to Rails `ActiveRecord::QueryMethods.none`
- Enhanced `ActiveResource::Collection#where` so that it returns `ActiveResource::Collection.none` if `resource_class` is missing.
    - This is useful for when `where` clauses are chained on an empty `ActiveResource::Collection`

## [0.1.5] - 2024-01-09
- Added callbacks to cache:
    - Create/POST, refresh cache after successful POST request
    - Update/PUT, refresh cache after successful PUT request
    - Destroy/DELETE, invalidate cache after successful DELETE request
- Fixed issue with generator for SQLCache strategy tables

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
