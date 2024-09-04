# Use the official Elixir image from Docker Hub
FROM elixir:1.16-alpine

# Install hex and rebar (Elixir build tools)
RUN mix local.hex --force && \
    mix local.rebar --force

# Create and set the working directory
WORKDIR /app

# Copy the mix.exs files to the container
COPY mix.exs ./

# Install Elixir dependencies
RUN mix deps.get --only prod

# Copy the rest of the application code
COPY . .

# Compile the application
RUN mix escript.build

# Set the default command to run your app
CMD ["./desafio_cli"]
