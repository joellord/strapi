# Running Strapi with containers

## Development
To use Strapi in a containerized development environment, you will need three independent containers. One will run the database, another one will have Strapi and finally the front-end will have its own container.

The database and back end servers will need a way to be able to communicate with each other. This can be achieved with a Docker network. Create your network with the command

```
docker network create strapi
```

You will also need three folders to hold the data from your containers. We will call those `/data`, `/app` and `/front` for the database, the strapi container and the front-end.

```
mkdir ./data && mkdir ./app && mkdir ./front
```

### Database container
The first thing that will be needed to start a Strapi instance is a database to persist your data. In this example, we will use a Postgres DB server running inside a container. This way, there is no need to go through the process of installing Postgres.

To run the server, you can use the `docker run` command with the `-d` argument so that it runs in the background. You can also name this container with the `--name` parameter. You will also need to specify a folder that will contain all of the data so that it can be reused next time you start the server. This is done with the `-v` parameter. Finally you will need to set up a few environment variables with `-e` to configure the database. Your command to start the container should look like this. Make sure to also use the `--network` parameter to connect this container to the network created earlier.

```
docker run --rm -d --name strapi-db -v $(pwd)/data:/var/lib/postgresql/data:z --network=strapi -e POSTGRES_DB=strapi -e POSTGRES_USER=strapi -e POSTGRES_PASSWORD=strapi postgres
```

After you executed this command, you can try a `docker ps` to validate that the container is started.

### Strapi back-end
Now that a database is configured, you can start your strapi instance. Once again, this will all run from a container. This time, you will use the `strapi/strapi` base image. You should still use `-d` to run it in the background and `--name` to name your container. Make sure to also add this container to the same network as the database. You should also map your local `/app` folder to `/srv/app` using the `-v` parameter so you can persist the files created by strapi using a local folder on your machine. Map a port on you operating system to access port 1337 inside the container. I'm using port 8080 so the address to connect to the strapi admin console will be `localhost:8080`. Finally, configure strapi to use the database you started in the previous step using environment variables.

```
docker run --rm -d --name strapi-dev -p 8080:1337 -v $(pwd)/app:/srv/app:z --network=strapi -e DATABASE_CLIENT=postgres -e DATABASE_NAME=strapi -e DATABASE_HOST=strapi-db -e DATABASE_PORT=5432 -e DATABASE_USERNAME=strapi -e DATABASE_PASSWORD=strapi strapi/strapi
```

If Strapi can't find any files in the local file sytem that you mapped, it will automatically create a new instance of a Strapi server. This can take a few minutes. To keep an eye on the status of the application creation, you can use `docker logs`

```
docker logs -f strapi-dev
```

Once you see a message saying that your Strapi server is strated, you can go to [http://localhost:8080](http://localhost:8080) to create you admin user.

Once your administrator is created, go ahead a create a new content-type and make is publicly available. You can find a full tutorial on how to do so on the [Strapi website](https://www.youtube.com/watch?v=VC9X9O5OFyc)

If you want to stop the logs in your console, use `Ctrl-C`.

### Front-end
Next up, you will create a front end. This UI will be composed of a simple HTML file that fetches the data from the Strapi API and displays them on the page.

An nginx server will be used to display the content. You can start the container is a similar way that you did for the other two. This time, map port 80 in the container to the port 8888 on your local machine. Also mount the `/front` folder to map to `/usr/share/nginx/html` inside your container. This is the default folder to serve files from with Nginx.

```
docker run --rm -d --name strapi-front -p 8888:80 -v $(pwd)/front:/usr/share/nginx/html:z nginx:1.17
```

Now go ahead and create your front-end application. You could use a React, VueJS or Angular application here but for the sake of this demo, it will be a simple HTML file. This file will do a `fetch` from the Strapi API to download the data and then create the necessary elements on the page using some JavaScript.

The HTML page will have a single `div` where the content will be displayed.

```
<body>
  <div id="content"></div>
</body>
```

You will need to add a `script` tag to include a configuration file. This `config.js` file will make it easier to later overwrite the location of you Strapi API.

Inside the index.html:
```
<script type="text/javascript" src="config.js">
```

The config.js file should create a global constant with the configuration.

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
      author.innerText = `${postData.admin_user.firstname} ${postData.admin_user.lastname} -- ${postData.publish_date}`;
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

Now that all the files are created, go to [http://localhost:8888](http://localhost:8888) to see your application. You should now see your fancy UI serving content from Strapi.

## Production
Once you are ready to deploy your application, you will need to create your own containers that contain all the necessary files and data. Those containers and what will end up going live on the web.