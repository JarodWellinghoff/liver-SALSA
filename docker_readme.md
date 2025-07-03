# SALSA Docker Setup

This document explains how to run SALSA (System for Automatic liver Lesion Segmentation And detection) using Docker.

## Prerequisites

- Docker Engine (v20.10+)
- Docker Compose (v2.0+)
- NVIDIA Container Toolkit (for GPU support)
- At least 8GB of available RAM
- At least 20GB of free disk space

## Quick Start

### 1. Clone the Repository

```bash
git clone https://github.com/radiomicsgroup/liver-SALSA
cd liver-SALSA
```

### 2. Download Model Weights

Download the model weights from Google Drive or Hugging Face (links in original README) and organize them as follows:

```
models/
├── Dataset001_TALES/
│   ├── nnUNetTrainer__nnUNetPlans__3d_lowres/
│   │   └── fold_0/
│   │       └── checkpoint_final.pth
│   └── nnUNetTrainer__nnUNetPlans__3d_cascade_fullres/
│       └── fold_0/
│           └── checkpoint_final.pth
```

### 3. Prepare Your Data

Create the following directory structure:

```
├── data/           # Input NIfTI files (.nii or .nii.gz)
├── output/         # Output segmentation files
├── models/         # Model weights (downloaded above)
└── docker-compose.yml
```

### 4. Build the Docker Image

```bash
docker-compose build
```

Or build manually:

```bash
docker build -t salsa:latest .
```

## Usage

### Option 1: Using Docker Compose (Recommended)

#### Single File Processing

```bash
# Process a single NIfTI file
docker-compose run --rm salsa /app/data/your_scan.nii.gz
```

#### Multiple Files Processing

Create a CSV file with paths to your scans:

```csv
PATHS
/app/data/scan1.nii.gz
/app/data/scan2.nii.gz
/app/data/scan3.nii.gz
```

Then run:

```bash
docker-compose run --rm salsa /app/data/scans.csv
```

### Option 2: Using Docker Directly

```bash
# Single file
docker run --gpus all --rm \
  -v $(pwd)/data:/app/data \
  -v $(pwd)/output:/app/output \
  -v $(pwd)/models:/app/models \
  salsa:latest /app/data/your_scan.nii.gz

# Multiple files from CSV
docker run --gpus all --rm \
  -v $(pwd)/data:/app/data \
  -v $(pwd)/output:/app/output \
  -v $(pwd)/models:/app/models \
  salsa:latest /app/data/scans.csv
```

### Option 3: Interactive Mode

For debugging or exploration:

```bash
docker-compose run --rm --entrypoint /bin/bash salsa
```

## Input Requirements

- **File Format**: NIfTI (.nii or .nii.gz)
- **Image Type**: CT scans containing liver
- **Orientation**: Any (will be handled automatically)
- **Spacing**: Any (will be resampled to 1x1x1mm³)

## Output

The pipeline generates:

1. **`{filename}_SALSA.seg.nrrd`** - Final segmentation in NRRD format
2. Intermediate files are automatically cleaned up

## GPU Support

The Docker image supports both CPU and GPU processing:

- **GPU**: Requires NVIDIA Container Toolkit
- **CPU**: Fallback mode (much slower)

To check GPU support:

```bash
docker run --gpus all --rm nvidia/cuda:12.1-base nvidia-smi
```

## Troubleshooting

### Common Issues

1. **"Models directory is empty"**

   ```bash
   # Ensure models are properly mounted and structured
   ls -la models/Dataset001_TALES/
   ```

2. **Out of memory errors**

   ```bash
   # Increase Docker memory limit or use CPU mode
   docker system prune -f
   ```

3. **Permission issues**

   ```bash
   # Fix file permissions
   sudo chown -R $USER:$USER data/ output/ models/
   ```

4. **CUDA out of memory**
   ```bash
   # Reduce batch size or use CPU
   export CUDA_VISIBLE_DEVICES=""
   ```

### Performance Tips

- **GPU**: Processing takes ~2-5 minutes per scan
- **CPU**: Processing takes ~15-30 minutes per scan
- **Memory**: Peak usage ~6-8GB RAM
- **Storage**: ~2-3GB temporary files per scan

## Environment Variables

The container supports these environment variables:

- `NNUNET_RESULTS`: Path to model weights (default: `/app/models`)
- `TOTALSEGMENTATOR_WEIGHTS`: Path to TotalSegmentator weights (default: auto-download)
- `CUDA_VISIBLE_DEVICES`: GPU selection (default: all available)

## Example Workflow

```bash
# 1. Prepare data
mkdir -p data output models
cp /path/to/your/scan.nii.gz data/

# 2. Download and organize models
# (follow instructions above)

# 3. Build image
docker-compose build

# 4. Process scan
docker-compose run --rm salsa /app/data/scan.nii.gz

# 5. Check results
ls -la output/
```

## Advanced Usage

### Custom Configuration

Create a custom `docker-compose.override.yml`:

```yaml
version: "3.8"
services:
  salsa:
    environment:
      - CUDA_VISIBLE_DEVICES=0 # Use only GPU 0
    volumes:
      - /custom/path/data:/app/data
      - /custom/path/output:/app/output
```

### Batch Processing Script

```bash
#!/bin/bash
# process_batch.sh

DATA_DIR="/path/to/your/data"
OUTPUT_DIR="/path/to/output"

for scan in "$DATA_DIR"/*.nii.gz; do
    echo "Processing: $(basename "$scan")"
    docker-compose run --rm salsa "/app/data/$(basename "$scan")"
done
```

## Support

For issues with the Docker setup:

1. Check the [troubleshooting](#troubleshooting) section
2. Verify your input files are valid NIfTI format
3. Ensure sufficient disk space and memory
4. Check Docker and NVIDIA Container Toolkit installation

For algorithm questions, contact the original authors:

- Dr. Raquel Perez-Lopez (rperez@vhio.net)
- Maria Balaguer (mbalaguer@vhio.net)
- Adrià Marcos (adriamarcos@vhio.net)

## License

Same as original SALSA project - see `license.txt`
