
docker run --rm -d --name strapi-dev -p 8080:1337 -v $(pwd)/app:/srv/app:z --network=strapi -e DATABASE_CLIENT=postgres -e DATABASE_NAME=strapi -e DATABASE_HOST=strapi-db -e DATABASE_PORT=5432 -e DATABASE_USERNAME=strapi -e DATABASE_PASSWORD=strapi strapi/strapi
docker run --rm -d --name strapi-db -v $(pwd)/data:/var/lib/postgresql/data:z --network=strapi -e POSTGRES_DB=strapi -e POSTGRES_USER=strapi -e POSTGRES_PASSWORD=strapi postgres
docker run --rm -d --name strapi-front -p 8888:80 -v $(pwd)/front:/usr/share/nginx/html:z nginx:1.17