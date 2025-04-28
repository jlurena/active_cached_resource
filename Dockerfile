FROM debian:bullseye-slim AS base

ENV LANG C.UTF-8
ENV LC_ALL C.UTF-8
ENV ASDF_DIR=/root/.asdf

# Install dependencies
RUN apt-get update && apt-get install -y \
    bash \
    build-essential \
    curl \
    git \
    libffi-dev \
    libssl-dev \
    perl \
    libreadline-dev \
    tzdata \
    libyaml-dev \
    zlib1g-dev

RUN git clone https://github.com/asdf-vm/asdf.git /root/.asdf --branch v0.14.0 && \
    . "$ASDF_DIR/asdf.sh" && \
    asdf plugin add ruby

# Ruby 3.2
FROM base AS ruby-3.2
RUN . "$ASDF_DIR/asdf.sh" && \
    asdf install ruby $(asdf latest ruby 3.2) && \
    asdf global ruby $(asdf latest ruby 3.2) && \
    gem install bundler

# Ruby 3.3
FROM base AS ruby-3.3
RUN . "$ASDF_DIR/asdf.sh" && \
    asdf install ruby $(asdf latest ruby 3.3) && \
    asdf global ruby $(asdf latest ruby 3.3) && \
    gem install bundler

# Ruby 3.4
FROM base AS ruby-3.4
RUN . "$ASDF_DIR/asdf.sh" && \
    asdf install ruby $(asdf latest ruby 3.4) && \
    asdf global ruby $(asdf latest ruby 3.4) && \
    gem install bundler

# Final Image with Application Code
FROM base AS final

# Copy and merge installed ASDF directory from ruby versions
COPY --from=ruby-3.2 /root/.asdf /tmp/.asdf-3.2
COPY --from=ruby-3.3 /root/.asdf /tmp/.asdf-3.3
COPY --from=ruby-3.4 /root/.asdf /tmp/.asdf-3.4
RUN cp -r /tmp/.asdf-3.2/* /root/.asdf/ && \
    cp -r /tmp/.asdf-3.3/* /root/.asdf/ && \
    cp -r /tmp/.asdf-3.4/* /root/.asdf/ && \
    rm -rf /tmp/.asdf*

WORKDIR /app

COPY bin bin
COPY lib lib
COPY spec spec
COPY scripts scripts
COPY sorbet sorbet
COPY .env .rubocop.yml .standard.yml active_cached_resource.gemspec Gemfile Rakefile .

CMD ['. "$ASDF_DIR/asdf.sh"', "&&", "tail", "-f", "/dev/null"]