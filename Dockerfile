FROM ruby:2.4-slim-stretch

LABEL maintainer="William Budington <bill@eff.org>"

RUN sed -i \
      -e 's|deb.debian.org/debian|archive.debian.org/debian|g' \
      -e 's|security.debian.org/debian-security|archive.debian.org/debian-security|g' \
      -e '/stretch-updates/d' \
      /etc/apt/sources.list && \
  echo 'Acquire::Check-Valid-Until "false";' > /etc/apt/apt.conf.d/99no-check-valid-until && \
  apt-get -o Acquire::Check-Valid-Until=false update && \
  apt-get install -y --no-install-recommends \
    build-essential \
    curl \
    default-libmysqlclient-dev \
    libpq-dev \
    git \
    qt5-default \
    xvfb \
    lsof \
    imagemagick \
    cron && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/* \
    /tmp/* \
    /var/tmp/*

# Create a symlink to what will be the phantomjs exec path
RUN ln -s /phantomjs-2.1.1-linux-x86_64/bin/phantomjs /bin/phantomjs

# Set up phantomjs, making sure to check the known good sha256sum
RUN curl -sLo phantomjs.tar.bz2 https://bitbucket.org/ariya/phantomjs/downloads/phantomjs-2.1.1-linux-x86_64.tar.bz2 && \
  bash -l -c '[ "`sha256sum phantomjs.tar.bz2 | cut -f1 -d" "`" = "86dd9a4bf4aee45f1a84c9f61cf1947c1d6dce9b9e8d2a907105da7852460d2f" ]' && \
  tar -jxvf phantomjs.tar.bz2 > /dev/null && \
  rm phantomjs.tar.bz2

# Datasources should be a persistent volume
VOLUME /datasources

RUN mkdir /opt/phantomdc
WORKDIR /opt/phantomdc
ADD Gemfile Gemfile.lock ./
ADD ./cwc/ ./cwc

RUN bundle install

ADD app ./app
ADD config ./config
ADD db ./db
ADD public ./public
ADD spec ./spec
ADD tasks ./tasks
ADD Procfile README.md Rakefile config.ru phantom-dc ./

RUN cp config/database.rb.example config/database.rb
RUN cp config/phantom-dc_config.rb.example config/phantom-dc_config.rb

ENV RACK_ENV production

ADD ./docker/app/entrypoint.sh ./
CMD ["thin", "start", "--port", "3001", "--threaded"]
ENTRYPOINT ["/opt/phantomdc/entrypoint.sh"]
