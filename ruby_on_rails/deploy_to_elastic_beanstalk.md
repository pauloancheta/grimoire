# Ruby on Rails / Deploy to Elastic Beanstalk

I have recently had the chance to deploy a rails application to Elastic Beanstalk using Docker. Here's the Dockerfile that I have used.

```Dockerfile
FROM library/ruby:2.5.5

SHELL ["/bin/bash", "-c"]

RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
RUN echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list
RUN apt-get update -qq && apt-get install -y build-essential nodejs yarn postgresql-client jq awscli

ENV APP_HOME /app
RUN mkdir $APP_HOME
WORKDIR $APP_HOME

RUN gem install bundler:2.1.2
ADD Gemfile* $APP_HOME/
RUN bundle install --without development test

ADD . $APP_HOME
RUN yarn install --check-files

EXPOSE 3000

ENTRYPOINT script/docker_entrypoint.sh
```

The entrypoint pulls secrets from SSM and exports them as environment variables which looks like this

```bash
#!/bin/bash

set -euo pipefail

: ${ENV:=staging}

get_param() {
  param=$(aws ssm get-parameter --name "$1" \
                                --region us-west-2 \
                                --with-decryption \
                                --output json \
          | jq -r '.Parameter.Value')
  echo "$param"
}

export OTHER_ENV=$(get_param "/${ENV}/OTHER_ENV")

exec "$@"
```

The last line ensures that I can run other services with my parameters.

Since I'm only using a single container on my stack, Dockerrun Version has to be set to 1. `Dockerrun.aws.json` must be present in the root of the application folder in order for EB to know how to run the application. Otherwise, it just looks for the command in the Dockerfile.

```json
{
  "AWSEBDockerrunVersion": "1",
  "Ports": [
    {
      "ContainerPort": "3000",
      "HostPort": "8080"
    }
  ],
  "Logging": "/app/log/",
  "Entrypoint": "script/docker_entrypoint.sh",
  "Command": "bundle exec rails s"
}
```
