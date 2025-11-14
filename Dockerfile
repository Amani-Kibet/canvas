# Use non-interactive frontend
ENV DEBIAN_FRONTEND=noninteractive

# -----------------------------
# Add apt repositories
# -----------------------------
RUN mkdir -p /etc/apt/keyrings

RUN curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key \
    | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg

RUN echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_${NODE_MAJOR}.x nodistro main" \
    > /etc/apt/sources.list.d/nodesource.list

RUN curl -fsSL https://dl.yarnpkg.com/debian/pubkey.gpg \
    | gpg --dearmor -o /etc/apt/keyrings/yarn.gpg

RUN echo "deb [signed-by=/etc/apt/keyrings/yarn.gpg] https://dl.yarnpkg.com/debian/ stable main" \
    > /etc/apt/sources.list.d/yarn.list

RUN curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc \
    | gpg --dearmor -o /etc/apt/keyrings/pgdg.gpg

RUN echo "deb [signed-by=/etc/apt/keyrings/pgdg.gpg] http://apt.postgresql.org/pub/repos/apt/ $(lsb_release -cs)-pgdg main" \
    > /etc/apt/sources.list.d/pgdg.list

RUN printf 'path-exclude /usr/share/doc/*\npath-exclude /usr/share/man/*' \
    > /etc/dpkg/dpkg.cfg.d/01_nodoc

RUN add-apt-repository ppa:git-core/ppa -ny

# -----------------------------
# Install packages quietly
# -----------------------------
RUN apt-get update -qq \
    && apt-get install -y --no-install-recommends \
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
    && rm -rf /var/lib/apt/lists/*

# -----------------------------
# Make gem folder
# -----------------------------
RUN mkdir -p /home/docker/.gem/ruby/$RUBY_MAJOR.0
