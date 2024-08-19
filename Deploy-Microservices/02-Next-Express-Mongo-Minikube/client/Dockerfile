# Use an official Node.js 20 image as a base # NextJS needs node version more than 18doc
FROM node:20

# Set the working directory
WORKDIR /app

# Copy package.json and package-lock.json
COPY package*.json ./

# Install dependencies
RUN npm install

# Copy the rest of your application code
COPY . .

# Build the Next.js application
RUN npm run build

# Expose the port
EXPOSE 3001

# Start the application
CMD ["npm", "start"]