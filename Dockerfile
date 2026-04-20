FROM nginx:alpine

COPY Tela-de-Login /usr/share/nginx/html

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]