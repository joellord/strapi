docker run -p 3080:80 -e BASE_URL=http://localhost:3181 -d --rm --name strapi-front-prod joellord/strapi-front
docker run -p 3181:1337 -d --rm --name strapi-prod --network=strapi joellord/strapi-prod
docker run -d --rm --name strapi-db --network=strapi joellord/strapi-db
