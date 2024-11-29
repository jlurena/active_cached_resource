# ActiveCachedResource
[ActiveResource](https://github.com/rails/activeresource) but with a caching layer.

## Installation

Install the gem and add to the application's Gemfile by executing:

    $ bundle add active_cached_resource

If bundler is not being used to manage dependencies, install the gem by executing:

    $ gem install active_cached_resource

## Usage

Check out the Wiki! https://github.com/jlurena/active_cached_resource/wiki

## Development

After checking out the repo, run `bin/setup` to install dependencies.
Run `rake` to run the linter and tests.
You can also run `bin/console` for an interactive prompt that will allow you to experiment.

Additionally, there is an `example` Rails Application you can play with.
In there you'll find two small rails app:

- Provider
    - This application contains the remote data.
- Consumer
    - This application consumes a remote resource from Provider.


## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/jlurena/active_cached_resource.

## Inspirations & Credits
- [CachedResource](https://github.com/mhgbrown/cached_resource)

Major differences between this gem and `CachedResource` are:
- This uses a custom, vendored version of the gem [`ActiveResource`](https://github.com/rails/activeresource) that adds the following features
    - Lazy `where` chaining
- Flexibility to add your own caching strategies, this gem comes built in with two of them:
    - Caching using `ActiveSupport`
    - Caching using `SQL`
