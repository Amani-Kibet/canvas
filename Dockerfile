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
  
  WORKDIR $APP_HOME
  
  # -----------------------------
  # Root user setup
  # -----------------------------
  USER root
  
  ARG USER_ID
  RUN if [ -n "$USER_ID" ]; then \
        usermod -u "$USER_ID" docker; \
        chown --from=9999 docker /usr/src/nginx /usr/src/app -R; \
      fi
  
  # -----------------------------
  # Create keyrings folder
  # -----------------------------
  RUN mkdir -p /etc/apt/keyrings
  
  # -----------------------------
  # NodeSource repo
  # -----------------------------
  ARG NODE_MAJOR=20
  RUN curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key \
      | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg && \
      CODENAME=$(grep '^VERSION_CODENAME=' /etc/os-release | cut -d= -f2) && \
      echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_${NODE_MAJOR}.x ${CODENAME} main" \
        > /etc/apt/sources.list.d/nodesource.list
  
  # -----------------------------
  # Yarn repo
  # -----------------------------
  RUN curl -fsSL https://dl.yarnpkg.com/debian/pubkey.gpg \
      | gpg --dearmor -o /etc/apt/keyrings/yarn.gpg && \
      echo "deb [signed-by=/etc/apt/keyrings/yarn.gpg] https://dl.yarnpkg.com/debian/ stable main" \
        > /etc/apt/sources.list.d/yarn.list
  
  # -----------------------------
  # PostgreSQL repo
  # -----------------------------
  RUN curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc \
        | gpg --dearmor -o /etc/apt/keyrings/pgdg.gpg && \
      CODENAME=$(grep '^VERSION_CODENAME=' /etc/os-release | cut -d= -f2) && \
      echo "deb [signed-by=/etc/apt/keyrings/pgdg.gpg] http://apt.postgresql.org/pub/repos/apt/ ${CODENAME}-pgdg main" \
        > /etc/apt/sources.list.d/pgdg.list
  
  # -----------------------------
  # Update repositories
  # -----------------------------
  RUN apt-get update -y
  
  # Install essentials before add-apt-repository
  RUN DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        apt-utils software-properties-common curl gnupg lsb-release ca-certificates
  
  # -----------------------------
  # Git PPA
  # -----------------------------
  RUN add-apt-repository ppa:git-core/ppa -ny || true
  
  # -----------------------------
  # Install dependencies
  # -----------------------------
  ENV DEBIAN_FRONTEND=noninteractive
  
  RUN apt-get update && \
      apt-get install -y --no-install-recommends \
        nodejs python3 python3-lxml tzdata unzip pbzip2 git && \
      apt-get install -y --no-install-recommends \
        libxmlsec1-dev libicu-dev libidn11-dev libgpg-error-dev \
        parallel postgresql-client-${POSTGRES_CLIENT} fontforge build-essential && \
      apt-get install -f -y && \
      rm -rf /var/lib/apt/lists/*
  
  # -----------------------------
  # Ruby & Node setup
  # -----------------------------
  RUN mkdir -p /home/docker/.gem/ruby/$RUBY_MAJOR.0
  RUN gem install bundler --no-document -v 2.5.10
  RUN find $GEM_HOME ! -user docker | xargs chown docker:docker
  RUN npm install -g npm@9.8.1
  RUN corepack enable && corepack prepare yarn@1.19.1 --activate
  ENV COREPACK_ENABLE_DOWNLOAD_PROMPT=0
  
  # -----------------------------
  # Switch to docker user
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
        /home/docker/.gem/ && \
      chown -R docker:docker \
        .yardoc log tmp node_modules public/dist \
        /home/docker/.bundle /home/docker/.cache/yarn /home/docker/.gem
  
  # -----------------------------
  # Copy project files
  # -----------------------------
  COPY --chown=docker:docker . .
  
  # -----------------------------
  # Default CMD
  # -----------------------------
  CMD ["rails", "server", "-b", "0.0.0.0"]
  