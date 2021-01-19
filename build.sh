USERNAME=joellord
docker build -t $USERNAME/strapi-front -f Dockerfile.front .
docker push $USERNAME/strapi-front
docker build -t $USERNAME/strapi-prod -f Dockerfile.strapi .
docker push $USERNAME/strapi-prod
docker build -t $USERNAME/strapi-db -f Dockerfile.db .
docker push $USERNAME/strapi-db
