# ---- Stage 1: Builder ----
    FROM rust:1.81 as builder

    # Install build dependencies
    RUN apt-get update && apt-get install -y --no-install-recommends libssl-dev pkg-config \
        && apt-get clean \
        && rm -rf /var/lib/apt/lists/*
    
    WORKDIR /app
    
    # Copy manifests
    COPY Cargo.toml Cargo.lock ./
    RUN mkdir src \
        && echo 'fn main() {println!("Building dependencies...")}' > src/main.rs \
        && cargo build --release \
        && rm -rf src \
        && rm -f target/release/deps/whoknows_rust_actix_backend*

    
    # Copy the actual source code
    COPY src ./src
    
    # Build the application
    RUN cargo build --release
    
    # --------------------------
    # ---- Stage 2: Runtime ----
    FROM debian:bookworm-slim
    
    RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates \
        && apt-get clean \
        && rm -rf /var/lib/apt/lists/*
    
    WORKDIR /app
    
    COPY --from=builder /app/target/release/whoknows_rust_actix_backend .
    
    RUN chmod +x ./whoknows_rust_actix_backend

    EXPOSE 8090
    
    # Start the application
    CMD ["./whoknows_rust_actix_backend"]