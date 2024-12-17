class Person < ActiveResource::Base
  cached_resource({cache_store: Rails.cache, cache_strategy: :active_support_cache})

  self.site = "http://localhost:3000"
  self.include_format_in_path = false

  self.user = "admin"
  self.password = "secret"
end