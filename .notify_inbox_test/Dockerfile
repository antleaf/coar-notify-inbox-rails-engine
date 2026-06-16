ARG RUBY_VERSION=3.3.0
FROM docker.io/library/ruby:$RUBY_VERSION-slim

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
      build-essential git libpq-dev libyaml-dev pkg-config postgresql-client && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

ENV BUNDLE_PATH="/usr/local/bundle"

# Build context is the engine root so path: "../" in Gemfile resolves at /app/
COPY . /app/
WORKDIR /app/.notify_inbox_test

ARG RAILS_ENV=production
ENV RAILS_ENV=$RAILS_ENV

RUN bundle install

RUN if [ "$RAILS_ENV" = "production" ]; then \
      SECRET_KEY_BASE_DUMMY=1 bundle exec rails assets:precompile; \
    fi

CMD ["bin/rails", "server", "-b", "0.0.0.0"]
