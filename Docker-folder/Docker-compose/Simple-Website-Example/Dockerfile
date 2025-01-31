FROM nginx:stable-alpine
COPY . /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]



# 1. docker build -t website .
# 2. docker run -d -p 8081:80 --mount type=bind source=$(pwd)/index.html,target=/usr/share/nginx/html website
