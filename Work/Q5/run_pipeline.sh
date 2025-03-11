#!/bin/bash

# Define shared directory for images
SHARED_DIR="$(pwd)/shared"

#Clean up old images
rm -rf "$SHARED_DIR"  # Remove the existing shared directory if it exists
mkdir -p "$SHARED_DIR"  # Create a fresh shared directory

echo "Building Python container..."
docker build -t plant_plotter -f Dockerfile.python .  # Build the Python container image

echo "Running Python container..."
docker run --rm -v "$SHARED_DIR":/output plant_plotter \
    --plant "Sunflower" \
    --height 120 125 130 135 \
    --leaf_count 50 55 60 65 \
    --dry_weight 5.0 5.5 6.0 6.5  # Run Python script with plant data

echo "📸 Images generated in directory $SHARED_DIR"

#Run Java container
echo "Building Java container..."
docker build -t watermark_adder -f Dockerfile.java .  # Build the Java container image

echo "Running Java container..."
docker run --rm -v "$SHARED_DIR":/images watermark_adder /images "Mahmoud Hleihil - ID 322244633"  # Add watermark to images

echo "All images watermarked in directory $SHARED_DIR"

# Clean up Docker containers and images
echo "Cleaning up Docker containers and images..."
docker rmi plant_plotter watermark_adder -f  # Remove the built images
docker system prune -f  # Clean up unused Docker images, containers, and objects

echo "Process completed successfully!"
