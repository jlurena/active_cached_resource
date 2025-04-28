#!/usr/local/bin/bash

set -e

export BUNDLE_SILENCE_ROOT_WARNING=1
export BUNDLE_IGNORE_MESSAGES=1

. "$ASDF_DIR/asdf.sh"
SPEC_RESULTS="coverage/spec_results"
mkdir -p "$SPEC_RESULTS"

# Ruby versions to test
LINTER_RUBY_VERSION=$(asdf latest ruby 3.2)
RUBY_VERSIONS=$(asdf list ruby)
# Maximum number of concurrent processes
MAX_PARALLEL=3
CURRENT_PARALLEL=0

run_rspec() {
  local ruby_version="$1"

  printf "\n********* Testing with Ruby $ruby_version *********\n\n"

  bundle install --quiet --no-cache
  # Run tests
  bundle exec rake
}

# Iterate over Ruby versions
for RUBY_VERSION in $RUBY_VERSIONS; do
  (
  asdf reshim ruby $RUBY_VERSION
  asdf shell ruby $RUBY_VERSION

  run_rspec "$RUBY_VERSION" "$RAILS_VERSION"
  ) &

  CURRENT_PARALLEL=$((CURRENT_PARALLEL + 1))
  while [ $CURRENT_PARALLEL -ge $MAX_PARALLEL ]; do
    sleep 1
    CURRENT_PARALLEL=$(jobs -r | wc -l)
  done
done

wait

printf "\n********* DONE *********\n"