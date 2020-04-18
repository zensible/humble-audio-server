
FROM ruby:2.3.7

# Install essential Linux packages
RUN apt-get update -qq && apt-get install -y \
    apt-transport-https \
    curl \
    build-essential \
    python-pip \
    git \
    libhyphen-dev \
    mysql-client \
    cmake \
    ruby-dev \
    libxslt-dev \
    zlib1g-dev \
    default-libmysqlclient-dev \
    libtag1-dev \
    pkg-config

#RUN curl -sL https://deb.nodesource.com/setup_6.x | bash -
#RUN apt-get install -y nodejs
#RUN npm install -g yarn

# Preparation:
# rm Gemfile
# cp ../web/Gemfile .
COPY ./Gemfile /Gemfile
COPY ./Gemfile.lock /Gemfile.lock

RUN gem install bundler -v 1.17.3
#RUN gem install nokogiri -v 1.10.3

RUN bundle _1.17.3_ install --system --gemfile=/Gemfile

RUN mkdir /app
WORKDIR /app

COPY . .

#RUN /app/bin/phantomjs -v

#RUN rm -f /Gem*
#RUN gem update bundler
RUN bundle install --system --gemfile=/app/Gemfile

RUN pip install --upgrade pip
RUN pip install 'zeroconf==0.19.1' --force-reinstall
RUN cd pychromecast && pip install -r requirements.txt

#CMD puma -C config/puma.rb

# Define the script we want run once the container boots
# Use the "exec" form of ENTRYPOINT so our script shuts down gracefully on
# SIGTERM (i.e. `docker stop`)
#ENTRYPOINT [ "/app/entrypoint.sh" ]
