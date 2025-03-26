# ---- Stage 1: Builder ----
# Use a slightly newer Rust version if possible, but 1.70 is okay
FROM rust:1.70 as builder

# Install build dependencies & cargo-chef
RUN apt-get update && apt-get install -y --no-install-recommends libssl-dev pkg-config \
    && cargo install cargo-chef \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# --- Build Plan ---
COPY Cargo.toml Cargo.lock ./
RUN mkdir src && echo "fn main() {}" > src/main.rs # Dummy src
RUN cargo chef prepare --recipe-path recipe.json

# --- Build Dependencies ---
# Consider adding --target x86_64-unknown-linux-gnu if needed for consistency
RUN cargo chef cook --release --recipe-path recipe.json

# --- Build Application ---
COPY src ./src
# Copy migrations folder for runtime use (if using sqlx::migrate!)
#COPY migrations ./migrations
# Ensure the binary name matches your Cargo.toml package name EXACTLY
RUN cargo build --release --bin whoknows_rust_actix_backend

# ---- Stage 2: Runtime ----
FROM debian:bullseye-slim

# Install runtime dependencies (only ca-certificates usually needed)
# sqlx bundles sqlite, libssl usually not needed unless dynamically linking specific features
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy the compiled application binary from the builder stage
COPY --from=builder /app/target/release/whoknows_rust_actix_backend .

# Copy migrations from builder stage IF your app runs them on startup
COPY --from=builder /app/migrations ./migrations

RUN chmod +x ./whoknows_rust_actix_backend

# Expose the port defined in docker-compose / .env (e.g., 8090)
# Your Actix application MUST be configured to listen on this port.
EXPOSE 8090

# Rely on docker-compose 'environment' section for DATABASE_URL

# Start the application
CMD ["./whoknows_rust_actix_backend"]