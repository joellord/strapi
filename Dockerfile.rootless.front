FROM nginx:1.17
COPY ./nginx.conf /etc/nginx/nginx.conf
RUN mkdir -p /code && chown -R nginx:nginx /code && chmod -R 755 /code
RUN chown -R nginx:nginx /var/cache/nginx && \
   chown -R nginx:nginx /var/log/nginx && \
   chown -R nginx:nginx /etc/nginx/conf.d
RUN touch /var/run/nginx.pid && \
   chown -R nginx:nginx /var/run/nginx.pid  
RUN chgrp -R root /var/cache/nginx /var/run /var/log/nginx /var/run/nginx.pid && \
   chmod -R 775 /var/cache/nginx /var/run /var/log/nginx /var/run/nginx.pid
COPY start_nginx.sh /
RUN chmod +x /start_nginx.sh
USER nginx
WORKDIR /code
COPY --chown=nginx ./front/*.* ./
RUN chmod -R ugo+rw /code
EXPOSE 8080
ENTRYPOINT [ "/start_nginx.sh" ]
