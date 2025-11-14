# Use root
USER root

# -----------------------
# Create keyrings directory
# -----------------------
RUN mkdir -p /etc/apt/keyrings

# -----------------------
# Node.js GPG key
# -----------------------
RUN curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key \
    | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg

RUN echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_20.x nodistro main" \
    > /etc/apt/sources.list.d/nodesource.list

# -----------------------
# Yarn GPG key
# -----------------------
RUN curl -fsSL https://dl.yarnpkg.com/debian/pubkey.gpg \
    | gpg --dearmor -o /etc/apt/keyrings/yarn.gpg

RUN echo "deb [signed-by=/etc/apt/keyrings/yarn.gpg] https://dl.yarnpkg.com/debian/ stable main" \
    > /etc/apt/sources.list.d/yarn.list

# -----------------------
# PostgreSQL key
# -----------------------
RUN curl -sS https://www.postgresql.org/media/keys/ACCC4CF8.asc \
    | apt-key add -

RUN echo "deb http://apt.postgresql.org/pub/repos/apt/ $(lsb_release -cs)-pgdg main" \
    > /etc/apt/sources.list.d/pgdg.list

# -----------------------
# Add Git PPA
# -----------------------
RUN add-apt-repository ppa:git-core/ppa -ny

# -----------------------
# Update & install packages
# -----------------------
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        nodejs \
        libxmlsec1-dev \
        python3-lxml \
        python-is-python3 \
        libicu-dev \
        libidn11-dev \
        libgpg-error-dev \
        parallel \
        postgresql-client-14 \
        tzdata \
        unzip \
        pbzip2 \
        fontforge \
        git \
        build-essential \
    && rm -rf /var/lib/apt/lists/*

# -----------------------
# Ensure gem directory exists
# -----------------------
RUN mkdir -p /home/docker/.gem/ruby/3.4.0
