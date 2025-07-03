#!/bin/bash

# SALSA Docker Setup Script
# This script helps set up the SALSA Docker environment

set -e

echo "🏥 SALSA Docker Setup Script"
echo "=================================="

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed. Please install Docker first."
    echo "Visit: https://docs.docker.com/get-docker/"
    exit 1
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    echo "❌ Docker Compose is not installed. Please install Docker Compose first."
    echo "Visit: https://docs.docker.com/compose/install/"
    exit 1
fi

echo "✅ Docker and Docker Compose are installed"

# Check if NVIDIA Container Toolkit is available (optional)
if command -v nvidia-smi &> /dev/null; then
    echo "✅ NVIDIA GPU detected"
    if docker run --rm --gpus all nvidia/cuda:12.1-base nvidia-smi &> /dev/null; then
        echo "✅ NVIDIA Container Toolkit is working"
        GPU_SUPPORT=true
    else
        echo "⚠️  NVIDIA Container Toolkit not properly configured"
        echo "   GPU acceleration will not be available"
        GPU_SUPPORT=false
    fi
else
    echo "ℹ️  No NVIDIA GPU detected - will use CPU mode"
    GPU_SUPPORT=false
fi

# Create directory structure
echo ""
echo "📁 Creating directory structure..."
mkdir -p data output models

echo "✅ Created directories:"
echo "   - data/    (place your NIfTI files here)"
echo "   - output/  (segmentation results will appear here)"
echo "   - models/  (place downloaded model weights here)"

# Copy the modified Python files to replace the originals
echo ""
echo "📝 Setting up modified code for Docker..."
if [ -f "codes/SALSA_stepONE_docker.py" ]; then
    cp codes/SALSA_stepONE_docker.py codes/SALSA_stepONE.py
    echo "✅ Updated SALSA_stepONE.py for Docker"
fi

if [ -f "codes/SALSA_stepTWO_docker.py" ]; then
    cp codes/SALSA_stepTWO_docker.py codes/SALSA_stepTWO.py
    echo "✅ Updated SALSA_stepTWO.py for Docker"
fi

# Check if models exist
echo ""
echo "🔍 Checking for model weights..."
if [ -d "models/Dataset001_TALES" ]; then
    echo "✅ Model weights found"
else
    echo "⚠️  Model weights not found!"
    echo ""
    echo "📥 Please download the model weights:"
    echo "   1. Download from Google Drive or Hugging Face (see README)"
    echo "   2. Extract and place in models/ directory"
    echo "   3. Structure should be:"
    echo "      models/"
    echo "      └── Dataset001_TALES/"
    echo "          ├── nnUNetTrainer__nnUNetPlans__3d_lowres/"
    echo "          │   └── fold_0/"
    echo "          │       └── checkpoint_final.pth"
    echo "          └── nnUNetTrainer__nnUNetPlans__3d_cascade_fullres/"
    echo "              └── fold_0/"
    echo "                  └── checkpoint_final.pth"
fi

# Build Docker image
echo ""
echo "🐳 Building Docker image..."
if [ "$GPU_SUPPORT" = true ]; then
    echo "   Building with GPU support..."
else
    echo "   Building with CPU support only..."
fi

docker-compose build

echo ""
echo "✅ Docker image built successfully!"

# Create example CSV file
echo ""
echo "📄 Creating example CSV file..."
cat > data/example_scans.csv << EOF
PATHS
/app/data/scan1.nii.gz
/app/data/scan2.nii.gz
EOF

echo "✅ Created data/example_scans.csv"

# Show usage examples
echo ""
echo "🚀 Setup complete! Usage examples:"
echo ""
echo "1. Process a single scan:"
echo "   docker-compose run --rm salsa /app/data/your_scan.nii.gz"
echo ""
echo "2. Process multiple scans from CSV:"
echo "   docker-compose run --rm salsa /app/data/example_scans.csv"
echo ""
echo "3. Interactive mode (for debugging):"
echo "   docker-compose run --rm --entrypoint /bin/bash salsa"
echo ""

if [ "$GPU_SUPPORT" = false ]; then
    echo "⚠️  Note: Running in CPU mode. Processing will be slower."
    echo "   For GPU acceleration, install NVIDIA Container Toolkit"
fi

echo ""
echo "📖 For more information, see README_Docker.md"
echo ""
echo "🎉 Ready to segment liver lesions with SALSA!"

read -p "Press any key to continue..."