FROM python:2.7

MAINTAINER Sebastian Ramirez <tiangolo@gmail.com>
# Install uWSGI
RUN pip install uwsgi

# Install cron
RUN apt-get update && apt-get -y install cron
ADD cron-remove-fonts /etc/cron.d/remove-fonts
RUN chmod 0644 /etc/cron.d/remove-fonts
RUN touch /var/log/cron.log

# Standard set up Nginx
ENV NGINX_VERSION 1.9.11-1~jessie

RUN wget -qO- http://nginx.org/keys/nginx_signing.key | apt-key add - \
	&& echo "deb http://nginx.org/packages/mainline/debian/ jessie nginx" >> /etc/apt/sources.list \
	&& apt-get update \
	&& apt-get install -y ca-certificates nginx=${NGINX_VERSION} gettext-base \
	&& rm -rf /var/lib/apt/lists/*
# forward request and error logs to docker log collector
RUN ln -sf /dev/stdout /var/log/nginx/access.log \
	&& ln -sf /dev/stderr /var/log/nginx/error.log
EXPOSE 80 443
# Finished setting up Nginx

# Make NGINX run on the foreground
RUN echo "daemon off;" >> /etc/nginx/nginx.conf
# Remove default configuration from Nginx
RUN rm /etc/nginx/conf.d/default.conf
# Copy the modified Nginx conf
COPY nginx.conf /etc/nginx/conf.d/

# Install Supervisord
RUN apt-get update && apt-get install -y supervisor \
&& rm -rf /var/lib/apt/lists/*
# Custom Supervisord config
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

COPY requirements.txt requirements.txt
RUN pip install -r requirements.txt
COPY ./app /app
WORKDIR /app

# Start cron
CMD cron && tail -f /var/log/cron.log

# Add maximum upload of 100 m
COPY upload_100m.conf /etc/nginx/conf.d/

CMD ["/usr/bin/supervisord"]
