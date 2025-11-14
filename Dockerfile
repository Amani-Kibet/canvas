# -----------------------------
  # Base image & arguments
  # -----------------------------
  ARG RUBY=3.4
  ARG RUBY_MAJOR=3
  FROM instructure/ruby-passenger:$RUBY-jammy
  LABEL maintainer="Instructure"
  
  ARG POSTGRES_CLIENT=14
  ENV APP_HOME=/usr/src/app/
  ENV RAILS_ENV=development
  ENV NGINX_MAX_UPLOAD_SIZE=10g
  ENV LANG=en_US.UTF-8
  ENV LANGUAGE=en_US.UTF-8
  ENV LC_CTYPE=en_US.UTF-8
  ENV LC_ALL=en_US.UTF-8
  ENV CANVAS_RAILS=8.0
  ENV NODE_MAJOR=20
  ENV GEM_HOME=/home/docker/.gem/$RUBY
  ENV PATH=${APP_HOME}bin:$GEM_HOME/bin:$PATH
  ENV BUNDLE_APP_CONFIG=/home/docker/.bundle
  ENV DEBIAN_FRONTEND=noninteractive
  
  WORKDIR $APP_HOME
  
  # -----------------------------
  # Root user setup
  # -----------------------------
  USER root
  
  # Allow host-mounted volumes to write correctly
  ARG USER_ID
  RUN if [ -n "$USER_ID" ]; then \
          usermod -u "${USER_ID}" docker; \
          chown --from=9999 docker /usr/src/nginx /usr/src/app -R; \
      fi
  
  # -----------------------------
  # Install dependencies quietly
  # -----------------------------
  RUN mkdir -p /etc/apt/keyrings \
      && curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg \
      && echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_${NODE_MAJOR}.x nodistro main" > /etc/apt/sources.list.d/nodesource.list \
      && curl -fsSL https://dl.yarnpkg.com/debian/pubkey.gpg | gpg --dearmor -o /etc/apt/keyrings/yarn.gpg \
      && echo "deb [signed-by=/etc/apt/keyrings/yarn.gpg] https://dl.yarnpkg.com/debian/ stable main" > /etc/apt/sources.list.d/yarn.list \
      && curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor -o /etc/apt/keyrings/pgdg.gpg \
      && echo "deb [signed-by=/etc/apt/keyrings/pgdg.gpg] http://apt.postgresql.org/pub/repos/apt/ $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list \
      && printf 'path-exclude /usr/share/doc/*\npath-exclude /usr/share/man/*' > /etc/dpkg/dpkg.cfg.d/01_nodoc \
      && add-apt-repository ppa:git-core/ppa -ny \
      && apt-get update -qq \
      && apt-get install -y -qq --no-install-recommends \
          nodejs \
          libxmlsec1-dev \
          python3-lxml \
          python-is-python3 \
          libicu-dev \
          libidn11-dev \
          libgpg-error-dev \
          parallel \
          postgresql-client-$POSTGRES_CLIENT \
          tzdata \
          unzip \
          pbzip2 \
          fontforge \
          git \
          build-essential \
      > /dev/null 2>&1 \
      && rm -rf /var/lib/apt/lists/* \
      && mkdir -p /home/docker/.gem/ruby/$RUBY_MAJOR.0
  
  # -----------------------------
  # Ruby & Node setup
  # -----------------------------
  RUN gem install bundler --no-document -v 2.5.10 \
      && find $GEM_HOME ! -user docker | xargs chown docker:docker
  
  RUN npm install -g npm@9.8.1 && npm cache clean --force
  RUN corepack enable && corepack prepare yarn@1.19.1 --activate
  
  # -----------------------------
  # Switch to Docker user
  # -----------------------------
  USER docker
  
  # -----------------------------
  # Writable directories
  # -----------------------------
  RUN mkdir -p \
          .yardoc \
          app/stylesheets/brandable_css_brands \
          app/views/info \
          config/locales/generated \
          log \
          node_modules \
          packages/js-utils/es \
          packages/js-utils/lib \
          packages/js-utils/node_modules \
          pacts \
          public/dist \
          public/javascripts/translations \
          reports \
          tmp \
          /home/docker/.bundle/ \
          /home/docker/.cache/yarn \
          /home/docker/.gem/ \
      && chown -R docker:docker \
          .yardoc log tmp node_modules public/dist \
          /home/docker/.bundle /home/docker/.cache/yarn /home/docker/.gem
  
  # -----------------------------
  # Copy project files
  # -----------------------------
  COPY --chown=docker:docker . .
  
  # -----------------------------
  # Default command
  # -----------------------------
  CMD ["rails", "server", "-b", "0.0.0.0"]
  