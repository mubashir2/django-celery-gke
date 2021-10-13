FROM python:3.9-slim as cloudgeeks

WORKDIR /app

ENV PYTHONUNBUFFERED 1

COPY ./requirements.txt /requirements.txt
COPY supervisord.conf /etc/supervisord.conf
RUN apt-get update
RUN apt-get install postgresql-client supervisor nginx -y
RUN apt-get install gcc libc-dev musl-dev  -y
RUN pip install -r /requirements.txt

ENV USER=app
ENV UID=12345
ENV GID=23456

RUN addgroup --system "${USER}" && adduser --disabled-password --system --group "${USER}" --no-create-home --uid "$UID" 
RUN chown -R "${USER}":"${USER}" /app


FROM cloudgeeks as runtime
COPY ./app /app
RUN chown -R "${USER}":"${USER}" /app
RUN chown -R "${USER}":"${USER}" /var/log/supervisor
COPY app.sh /app/app.sh
RUN  chmod +x /app/app.sh
COPY celery.conf /etc/supervisor/conf.d/celery.conf
COPY celery_beat.conf /etc/supervisor/conf.d/celery_beat.conf
COPY supervisord.conf /etc/supervisord.conf

# Switch to app user
EXPOSE 8000
USER app
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]
