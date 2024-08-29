## See how the bad example of Dockerfile which can explode the image size to 1GB

```
# Use Node.js base image
FROM node:16

# Set the working directory
WORKDIR /app

# Copy package.json and package-lock.json
COPY package*.json ./

# Install dependencies
RUN npm install

# Copy the rest of the application code
COPY . .

# Expose the port your Express app runs on
EXPOSE 3000

# Start the application
CMD ["npm", "start", "3002"]

```

## What to inclide to reduce the image size
1. Use a Smaller Base Image
    - Use an `alpine` variant of the Node.js image, 
    - which is a minimal Docker image based on Alpine Linux.
    - This significantly reduces the base image size.

2. Multistage Builds
    - Use `multistage` builds to install dependencies in one stage and copy only the necessary files to the final image.
    - This helps to avoid including development dependencies and other unnecessary files in the final image.

3. Optimize npm Install
    - Use `npm ci` instead of npm install for faster, more reliable builds. 
    - It only installs the dependencies listed in the `package-lock.json`.
    - Omit development dependencies in production builds with npm ci --only=production or npm ci --omit=dev.

4. Ignore Unnecessary Files
    - Just have a `.dockerignore` file that excludes files not needed in the Docker image, 
    - such as documentation, test directories, or local configuration files.
            ```
                node_modules
                npm-debug.log
                Dockerfile
                .dockerignore
                .git
                .env
            ```

### Better version of Dockerfile for expressJS

```
# Stage 1: Build the application
FROM node:16-alpine AS build

# Set the working directory
WORKDIR /app

# Copy package.json and package-lock.json
COPY package*.json ./

# Install dependencies
RUN npm ci --only=production

# Copy the rest of the application code
COPY . .

# Stage 2: Create the final image
FROM node:16-alpine

# Set the working directory
WORKDIR /app

# Copy only the necessary files from the build stage
COPY --from=build /app .

# Expose the port your Express app runs on
EXPOSE 3000

# Start the application
CMD ["npm", "start"]
```