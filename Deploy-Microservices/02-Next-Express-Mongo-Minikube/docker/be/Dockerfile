# Stage 1: Build the application
FROM node:16-alpine AS build

# Set the working directory
WORKDIR /app

# Copy package.json and package-lock.json
COPY server/package*.json ./

# Install all dependencies (including dev dependencies) for the build stage
RUN npm install

# Copy the rest of the application code
COPY server ./

# Stage 2: Create the final image
FROM node:16-alpine

# Set the working directory
WORKDIR /app

# Copy only the necessary files from the build stage
COPY --from=build /app/package*.json ./
COPY --from=build /app/node_modules /app/node_modules
COPY --from=build /app ./

# Expose the port your Express app runs on
EXPOSE 3002

# Start the application
CMD ["npm", "start"]
