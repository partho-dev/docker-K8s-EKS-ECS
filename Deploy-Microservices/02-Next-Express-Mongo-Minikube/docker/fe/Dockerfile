# Stage 1: Build the Next.js application
FROM node:20-alpine AS builder

# Set the working directory
WORKDIR /app

# Copy package.json and package-lock.json from client folder
COPY client/package*.json ./

# Install all dependencies (including dev dependencies) for the build stage
RUN npm install

# Copy the rest of the application code from client folder
COPY client/ ./

# Build the Next.js application
RUN npm run build

# Stage 2: Use a lightweight image for production
FROM node:20-alpine

# Set the working directory
WORKDIR /app

# Copy package.json and package-lock.json from the builder stage
COPY --from=builder /app/package*.json ./

# Install only production dependencies
RUN npm install --production

# Copy only the necessary files from the builder stage
COPY --from=builder /app/.next /app/.next
COPY --from=builder /app/public /app/public
COPY --from=builder /app/node_modules /app/node_modules
COPY --from=builder /app/app /app/app

# Expose the port
EXPOSE 3000

# Start the Next.js application
CMD ["npm", "start"]