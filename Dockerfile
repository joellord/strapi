FROM postgres:12
ENV POSTGRES_DB=strapi
ENV POSTGRES_USER=strapi
ENV POSTGRES_PASSWORD=strapi
COPY ./data /var/lib/postgresql/data
RUN mkdir temp
RUN groupadd non-root-postgres-group
RUN useradd non-root-postgres-user --group non-root-postgres-group
RUN chown -R non-root-postgres-user:non-root-postgres-group /temp
RUN chmod 777 /temp
USER non-root-postgres