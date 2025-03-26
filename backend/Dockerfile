# ---- Stage 1: Builder ----
    FROM rust:1.81 as builder

    # Install build dependencies
    RUN apt-get update && apt-get install -y --no-install-recommends libssl-dev pkg-config \
        && apt-get clean \
        && rm -rf /var/lib/apt/lists/*
    
    WORKDIR /app
    
    # Copy manifests
    COPY Cargo.toml Cargo.lock ./
    
    # Create a dummy main.rs to build dependencies
    RUN mkdir -p src && echo 'fn main() { println!("Dummy"); }' > src/main.rs
    
    # Build dependencies - this layer will be cached unless Cargo.toml/Cargo.lock changes
    RUN cargo build --release
    
    # Remove the dummy source file and the built binary
    RUN rm -f target/release/deps/whoknows_rust_actix_backend*
    
    # Copy the actual source code
    COPY src ./src
    
    # Build the application
    RUN cargo build --release
    
    # ---- Stage 2: Runtime ----
    FROM debian:bullseye-slim
    
    # Install runtime dependencies (only ca-certificates usually needed)
    RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates \
        && apt-get clean \
        && rm -rf /var/lib/apt/lists/*
    
    WORKDIR /app
    
    # Copy the compiled application binary from the builder stage
    COPY --from=builder /app/target/release/whoknows_rust_actix_backend .
    
    RUN mkdir -p /app/migrations
    
    RUN chmod +x ./whoknows_rust_actix_backend
    
    # Expose the port defined in docker-compose / .env
    EXPOSE 8090
    
    # Start the application
    CMD ["./whoknows_rust_actix_backend"]