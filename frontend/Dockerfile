# ---- Stage 1: Build ----
   FROM node:18-alpine as builder
   WORKDIR /app
   COPY package.json package-lock.json* ./
   RUN npm ci
   COPY . .
   RUN npm run build
   
   # ---- Stage 2: Serve ----
   FROM nginx:1.25-alpine
   RUN rm /etc/nginx/conf.d/default.conf
   COPY nginx.conf /etc/nginx/conf.d/default.conf
   COPY --from=builder /app/dist /usr/share/nginx/html
   
   EXPOSE 91
   
   CMD ["nginx", "-g", "daemon off;"]