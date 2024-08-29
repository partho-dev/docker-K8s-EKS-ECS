# Stage 1: Build the application
FROM node:16-alpine AS build

# Set the working directory
WORKDIR /app

# Copy package.json and package-lock.json
COPY package*.json ./

# Install dependencies, use npm ci instead of npm install
# Avoid installation of dev dependabcies packages

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