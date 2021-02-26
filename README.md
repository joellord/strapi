# Running Strapi with containers

## Development
To use Strapi in a containerized development environment, you will need three independent containers. One will run the database, another one will have Strapi, and finally, the front-end will have its own container.

The database and back-end servers will need a way to be able to communicate with each other. You can achieve this with a Docker network. Create your network with the command

```
docker network create strapi
```

You will also need three folders to hold the data from your containers. We will call those `/data`, `/app` and `/front` for the database, the strapi container and the front-end.

```
mkdir ./data && mkdir ./app && mkdir ./front
```

### Database container
The first thing you will need to start a Strapi instance is a database to persist your data. In this example, we will use a MySQL DB server running inside a container. This way, there is no need to go through the process of installing MySQL.

To run the server, you can use the `docker run` command with the `-d` argument to run in the background. You can also name this container with the `--name` parameter. You will also need to specify a folder that will contain all of the data so that you can reuse it next time you start the server. This is done with the `-v` parameter. Finally, you will need to set up a few environment variables with `-e` to configure the database. Your command to start the container should look like this. Make sure to use the `--network` parameter to connect this container to the network created earlier.

```
docker run --rm -d --name strapi-db -v $(pwd)/data:/var/lib/mysql:z --network=strapi -e MYSQL_DATABASE=strapi -e MYSQL_USER=strapi -e MYSQL_PASSWORD=strapi -e MYSQL_ROOT_PASSWORD=strapi-admin mysql:5.7
```

After you executed this command, you can try a `docker ps` to validate that the container is started.

### Strapi back-end
Now that a database is configured, you can start your strapi instance. Once again, this will all run from a container. This time, you will use the `strapi/strapi` base image. You can still use `-d` to run it in the background and `--name` to name your container. Make sure to also add this container to the same network as the database. You should also map your local `/app` folder to `/srv/app` using the `-v` parameter so you can persist the files created by strapi using a local folder on your machine. Map a port on your operating system to access port 1337 inside the container. I'm using port 8080, so the address to connect to the strapi admin console will be `localhost:8080`. Finally, configure strapi to use the database you started in the previous step using environment variables.

```
docker run --rm -d --name strapi-dev -p 8080:1337 -v $(pwd)/app:/srv/app:z --network=strapi -e DATABASE_CLIENT=mysql -e DATABASE_NAME=strapi -e DATABASE_HOST=strapi-db -e DATABASE_PORT=3306 -e DATABASE_USERNAME=strapi -e DATABASE_PASSWORD=strapi strapi/strapi
```

If Strapi can't find any files in the local file system that you mapped, it will automatically create a new instance of a Strapi server. This can take a few minutes. To keep an eye on the application creation status, you can use `docker logs`.

```
docker logs -f strapi-dev
```

If you want to stop the logs in your console, use `Ctrl-C`.

Once you see a message saying that your Strapi server is started, you can go to [http://localhost:8080/admin](http://localhost:8080/admin) to create your admin user.

After you created your administrator, go ahead a create a new content-type and make it publicly available. You can find a full tutorial on how to do so on the [Strapi website](https://www.youtube.com/watch?v=VC9X9O5OFyc)

For some content that will work with the next step, you can create a *Content-Type* for _Posts_. It will have four fields: _title_, _author_ (a relationship to Users), _publish\_date_ and _content_.

### Front-end
Next up, you will create a front end. This UI will be composed of a simple HTML file that fetches the Strapi API data and displays it on the page.

You will use an Nginx server to display the content. You can start the container in a similar way that you did for the other two. This time, map port 80 in the container to port 8888 on your local machine. Also mount the `/front` folder to map to `/usr/share/nginx/html` inside your container. This is the default folder to serve files from with Nginx.

```
docker run --rm -d --name strapi-front -p 8888:80 -v $(pwd)/front:/usr/share/nginx/html:z nginx:1.17
```

Now go ahead and create your front-end application. You could use a React, VueJS or Angular application here, but it will be a simple HTML file for the sake of this demo. This file will do a `fetch` from the Strapi API to download the data and then create the necessary elements on the page using some JavaScript.

The HTML page will have a single `div` where the JavaScript code will append the API's content. You can create his index.html file in the /front folder.

_front/index.html_
```
<body>
  <div id="content"></div>
</body>
```

You will need to add a `script` tag to include a configuration file. This `config.js` file will make it easier to overwrite the location of your Strapi API later.

Inside the index.html:
```
<script type="text/javascript" src="config.js">
```

The front/config.js file should create a global constant with the configuration.

_front/config.js_
```
const config = {
  BASE_URL: "http://localhost:8080"
}
```

Finally, in the index.html file, add another `script` tag that will contain the following code to download the content and display it on the page.

```
window.addEventListener("DOMContentLoaded", e => {
  console.log("Loading content from Strapi");

  const BASE_URL = config.BASE_URL;

  const BLOG_POSTS_URL = `${BASE_URL}/posts`;

  fetch(BLOG_POSTS_URL).then(resp => resp.json()).then(posts => {
    for(let i = 0; i < posts.length; i++) {
      let postData = posts[i];
      let post = document.createElement("div");
      let title = document.createElement("h2");
      title.innerText = postData.title;
      let author = document.createElement("h3");
      author.innerText = `${postData.author.firstname} ${postData.author.lastname} -- ${postData.publish_date}`;
      let content = document.createElement("div");
      content.innerText = postData.content;
      post.appendChild(title);
      post.appendChild(author);
      post.appendChild(content);
      document.querySelector("#content").appendChild(post);
    }
  });
});
```

Now that all the files are created go to [http://localhost:8888](http://localhost:8888) to see your application. You should now see your fancy UI serving content from Strapi.

## Production
Once you are ready to deploy your application, you will need to create your own containers that contain all the necessary files and data. Those containers are what will end up going live on the web.

For each container, you will need to create a Dockerfile. You will use those files to create your containers with the actual content, and you will then be able to deploy those containers to Kubernetes.

### Database
There is a good chance for your database that you already have one in production and that you won't want to overwrite the content. For this reason, you will also use the default MySQL image in production. If you want to import the SQL content later on, though, you can use Docker to run a `mysqldump` command on your database.

```
docker exec strapi-db /bin/bash -c 'mysqldump strapi -ustrapi -pstrapi' | tee strapi-db.sql
```

NOTE: This command uses `tee` to copy the content to a file. If you don't have that command, you can copy the docker command's output into a file named `strapi-db.sql`.

This file will be later imported into the production database if needed.

### Strapi back-end
You will need to create a `Dockefile.back` to build your container for the back-end.

To do so, start from the strapi base image `FROM strapi/base`. Change the working directory to `/opt/app` and copy all the local files into the container. Next, expose port 1337 and set all your environment variables. Don't forget to add an environment variable for `NODE_ENV=production`. Finally, execute the `yarn build` to build all the production resources and use the `CMD` command to start the back-end when the container is started. For more information on how to use the Strapi base image, you can check out the documentation at https://github.com/strapi/strapi-docker#how-to-use-strapibase.

_Dockerfile.back_
```
FROM strapi/base
WORKDIR /opt/app
COPY ./app/package.json ./
COPY ./app/yarn.lock ./
RUN yarn install
COPY ./app .
ENV NODE_ENV production
ENV DATABASE_CLIENT=mysql 
ENV DATABASE_NAME=strapi
ENV DATABASE_HOST=strapi-db
ENV DATABASE_PORT=3306
ENV DATABASE_USERNAME=strapi
ENV DATABASE_PASSWORD=strapi
RUN yarn build
EXPOSE 1337
CMD ["yarn", "start"]
```

### Front-end
For the front-end, you'll have to do a bit of bash scripting to be able to use an environment variable to specify the URL of your Strapi server. You can find out more about how to use environment variables with front-end containers at http://github.com/joellord/frontend-containers. 

First, start with the `nginx:1.17` base image and change the working directory to `/usr/share/nginx/html`. In there, copy all the files from your local system into the container.

The next step involves using `sed` to change the value between the double quotes following the key `BASE_URL` and change that value to `$BASE_URL.` The result is piped into a new file called config.new.js. Finally, the file is renamed config.js to overwrite the original file. 

The result inside the container will be a new config.js file that looks like this while leaving the original file in your local file system intact.

```
const config = {
  BASE_URL: "$BASE_URL"
}
```

Finally, you will need to use `envsubst` to change the value of $BASE_URL to the environment variable's actual value. All of this is done in the `ENTRYPOINT`, so it only gets done when someone uses a Docker run. The benefit of doing it in an Entrypoint instead of a `RUN` is that it'll enable you to specify different values for the base URL based on where you are running this container.

To do so, you can use a `cat` command to pipe the config.js file into `envsubst`. The output is then piped to `tee` to create a new `config.new.js` file. That file is then renamed and overwrites the previous config file. Finally, the `nginx -g 'daemon off;'` command is used to start the Nginx server.

_Dockerfile.front_
```
FROM nginx:1.17
WORKDIR /usr/share/nginx/html
COPY ./front/*.* ./
RUN sed s/BASE_URL\:\ \"[a-zA-Z0-9:\/]*\"/BASE_URL\:\ \"\$BASE_URL\"/g config.js > config.new.js && mv config.new.js config.js
ENTRYPOINT cat config.js |  envsubst | tee config.new.js && mv config.new.js config.js && nginx -g 'daemon off;'
```

### Build the containers
Now that you have all your Dockerfiles ready, you can build those containers and push them to your favourite image registry. Don't forget to change the name of your images to use your username for that registry.

```
docker build -t $DOCKER_USERNAME/strapi-front -f Dockerfile.front .
docker build -t $DOCKER_USERNAME/strapi-back -f Dockerfile.back .
docker push $DOCKER_USERNAME/strapi-front
docker push $DOCKER_USERNAME/strapi-back
```

## Package and Run
Now that you have containers with all of your code and all your data, you are ready to deploy these containers somewhere.

### Docker
If you want to run this application, you can start all containers as it would look like in production.

The commands to start the containers are similar to those you used earlier in development mode but with the mounted volumes and without the environment variables. The source code and environment variables were taken care of in the Dockerfile. Also, note how we add an environment variable to start the front-end to specify where the Strapi API is located.

```
docker run --rm -d --name strapi-db -v $(pwd)/data:/var/lib/mysql:z --network=strapi -e MYSQL_DATABASE=strapi -e MYSQL_USER=strapi -e MYSQL_PASSWORD=strapi -e MYSQL_ROOT_PASSWORD=strapi-admin mysql:5.7
docker run --rm -d --name strapi -p 1337:1337 --network=strapi $DOCKER_USERNAME/strapi-back
docker run --rm -d --name strapi-front -p 8080:80 -e BASE_URL=http://localhost:1337 $DOCKER_USERNAME/strapi-front
```

### Docker-compose
If you want to share all of this with anyone else, you could provide them with a `docker-compose.yaml` file. This is a tool to manage multiple containers at once without the need for multiple bash commands. 

```
version: '3'
services:
  strapi-db:
    image: mysql:5.7
    volumes:
      - ./data:/var/lib/mysql
    networks:
      - strapi
  strapi-back:
    image: $DOCKER_USERNAME/strapi-back
    ports:
      - '1337:1337'
    networks:
      - strapi
  strapi-front:
    image: $DOCKER_USERNAME/strapi-front
    ports: 
      - '8080:80'
    environment:
      BASE_URL: http://localhost:1337
networks:
  strapi:
```

## Deploy
Once you have created all of your containers, you can deploy the application into a Kubernetes cluster. To do so, you will need to use some YAML files to create all the necessary assets. For more details on each of these assets, you can check out [Kubernetes By Example](http://kubernetesbyexample.com).

### Minikube
To test out the deployment, you can use a smaller version of Kubernetes or OpenShift to run locally on your own machine. For the following examples, I've used [Minikube](https://kubernetes.io/docs/tutorials/hello-minikube/).

### Kubernetes
[Persistent Volumes](https://kubernetesbyexample.com/pv/) and Persistent Volume Claims setup tend to vary from one cloud provider to another. For this reason, the database in this example will not persist data. For more information on how to persist data, look at the documentation on your cloud provider.

For the database, we will need to create a [Deployment](https://kubernetesbyexample.com/deployments/). To do so, create a YAML file that will describe your deployment. You can give it a name, and in the spec, you will create a template for the pods. Those pods will have a single container which will be the ones that you've pushed to your registry.

_deploy-db.yaml_
```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: strapi-db
spec:
  selector:
    matchLabels:
      component: db
  template:
    metadata:
      labels:
        component: db
    spec:
      containers:
      - name: strapi-db
        image: mysql:5.7
        env: 
          - name: MYSQL_DATABASE
            value: strapi 
          - name: MYSQL_USER
            value: strapi 
          - name: MYSQL_PASSWORD
            value: strapi 
          - name: MYSQL_ROOT_PASSWORD
            value: strapi-admin
```

Once you have your file, you can apply it to your cluster using `kubectl`.

```
kubectl apply -f ./deploy-db.yaml
```

For your back-end to find those pods inside the cluster, you will need to create a [Service](https://kubernetesbyexample.com/services/) to expose this pod. You will be using the defaults here, so you can use `kubectl` to create this service.

```
kubectl expose deployment strapi-db --port 3306
```

If you want to import data from your development environment SQL, you can run the following commands. This will copy the .sql file to the pod and then run a MySQL command to run it in the database.

```
kubectl cp ./strapi-db.sql $(kubectl get pod -l component=db | awk 'NR>1 {print $1}'):/tmp/strapi-db.sql
kubectl exec -t $(kubectl get pod -l component=db | awk 'NR>1 {print $1}') -- /bin/bash -c 'mysql strapi -ustrapi -pstrapi < /tmp/strapi-db.sql'
```

You can also create your deployments for the back-end and the front-end portions of your application. The Strapi back-end will be the same as the database deployment apart from the name, label, and container image.

_deploy-back.yaml_
```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: strapi-back
spec:
  selector:
    matchLabels:
      app: strapi
      component: back
  template:
    metadata:
      labels:
        app: strapi
        component: back
    spec:
      containers:
      - name: strapi-back
        image: joellord/strapi-back
```

The front-end uses a similar structure, but you will also need to set the environment variable for the BASE_URL of the back-end. For now, you can set the value of that environment variable to `/api`. You will expose that route in a future step. Finally, you'll also need to expose the container port 80 so that this container is eventually available to the outside world.

_deploy-front.yaml_
```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: strapi-front
spec:
  selector:
    matchLabels:
      component: front
  template:
    metadata:
      labels:
        component: front
    spec:
      containers:
      - name: front
        image: joellord/strapi-front
        ports:
          - containerPort: 80
        env:
          - name: BASE_URL
            value: /api
```

Now that your deployment files are created, you can apply them to your cluster and create the services for each one of them.

```
kubectl apply -f ./deploy-back.yaml
kubectl apply -f ./deploy-front.yaml
kubectl expose deployment strapi-back --port 1337
kubectl expose deployment strapi-front --port 80
```

Everything is now running inside your cluster. The only thing you need now is to expose the front-end and back-end services to the outside world. To do so, you will need to use an [Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/).

The ingress you will create here will expose the front-end as the default service to direct the traffic to. That means that any incoming request to your cluster will go to the front-end by default.

You will also add a rule that will redirect any traffic to `/api/*` to the back-end service. The request will then be rewritten when sent to that service to remove the `/api` part of the URL. That is done with the Nginx annotation in the metadata.

_ingress.yaml_
```
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: main-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /$2
spec:
  rules:
  - http:
      paths:
        - path: /api(/|$)(.*)
          pathType: Prefix
          backend:
            service:
              name: strapi-back
              port:
                number: 1337
        - path: /()(.*)
          pathType: Prefix
          backend:
            service:
              name: strapi-front
              port:
                number: 80
```

Go ahead and apply this file to your cluster. If you are using `minikube` and never use ingresses before, you might need to enable the add-on.

```
# For minikube users
minikube addons enable ingress

kubectl apply -f ./ingress.yaml
```

You now have everything needed to run your Strapi application in a Kubernetes cluster. Point your browser to the cluster URL, and you should see the full application running in your cluster. If you're using minikube, you can use the command `minikube ip` to get your cluster's address.

### OpenShift
If you are using [OpenShift](http://openshift.com), it can be even easier to deploy your application. 

You can test it out with the [Developer Sandbox](https://developers.redhat.com/developer-sandbox), which gives you access to an OpenShift cluster for free for 14 days.

The CLI tool `oc` that you use to manage your cluster can create a deployment directly from an image. To deploy your application, you can use:

```
oc new-app mysql:5.7 MYSQL_USER=strapi MYSQL_PASSWORD=strapi MYSQL_DATABASE=strapi -l component=db --name strapi-db
oc new-app joellord/strapi-back-openshift --name strapi-back
oc new-app joellord/strapi-front-openshift --name strapi-front
```

NOTE: To run images on OpenShift, they need to run as non-root users. You can find out more about non-root images at https://github.com/joellord/frontend-containers. The Dockerfiles used for this project can be found in the git repository for this post under Dockerfile.rootless.back and Dockerfile.rootless.front.

Next, you'll want to expose those applications to the outside world. Once again, OpenShift has a neat object called a Route which you can also create from the CLI. Use the `oc expose` command to expose the back-end and front-end to the outside world.

```
oc expose service strapi-back
oc expose service strapi-front --port=8080
```

Now that your back-end is exposed, you will need to set the environment variable in your front end to the back-end route. First, start by getting the public route for the Strapi API:

```
oc get routes
```

You should see all the routes that you created. You can store the route for the back end in a variable and then set it as an environment variable using `oc set env`:

```
export BACKEND_ROUTE=$(oc get routes | grep strapi-back | awk '{print $2}')
oc set env deployment/strapi-front BASE_URL=http://$BACKEND_ROUTE
```

You can now access your Strapi application using the route for the strapi-front service.

## Summary
When you are ready to put your Strapi application in production, the first step will be to containerize your whole setup. Once you have that done, you can deploy those containers in Kubernetes. You also saw in this post how easy it could be to deploy to OpenShift.