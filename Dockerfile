# syntax = docker/dockerfile:1

ARG RUBY_VERSION=3.3.6
FROM registry.docker.com/library/ruby:$RUBY_VERSION-slim AS base

WORKDIR /app

ENV BUNDLE_DEPLOYMENT="1" \
  BUNDLE_WITHOUT="development"

RUN apt-get update -qq && \
apt-get install --no-install-recommends -y build-essential

# Make sure Bundler version matches the bundler version in Gemfile.lock
RUN gem install bundler -v 2.6.1

# Install application gems
COPY Gemfile Gemfile.lock ./
RUN bundle install

# Create a non-root syncuser that matches the host's user id and group.
ARG GID=1012
ARG UID=2001

RUN getent group $GID || groupadd -g $GID syncgroup && \
getent passwd $UID || useradd -u $UID -g $GID -m --shell /bin/bash syncuser

# Copy application code
COPY . .

# Own the runtime files as the syncuser
RUN chown -R $UID:$GID /app

USER syncuser

ENTRYPOINT ["bundle", "exec", "ruby", "main.rb"]
CMD ["--help"]