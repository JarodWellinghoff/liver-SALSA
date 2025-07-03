#!/bin/bash
set -e

# Initialize conda
source /opt/conda/etc/profile.d/conda.sh

# Function to display usage
usage() {
    echo "Usage: docker run [docker options] salsa:latest <input_path>"
    echo ""
    echo "Arguments:"
    echo "  input_path    Path to NIfTI file (.nii/.nii.gz) or CSV file with paths"
    echo ""
    echo "Examples:"
    echo "  # Process single scan"
    echo "  docker run -v /host/data:/app/data -v /host/output:/app/output salsa:latest /app/data/scan.nii.gz"
    echo ""
    echo "  # Process multiple scans from CSV"
    echo "  docker run -v /host/data:/app/data -v /host/output:/app/output salsa:latest /app/data/scans.csv"
    echo ""
    echo "Note: Make sure your models are mounted to /app/models"
    exit 1
}

# Check if input argument is provided
if [ $# -eq 0 ]; then
    echo "Error: No input path provided"
    usage
fi

INPUT_PATH="$1"

# Check if input file exists
if [ ! -f "$INPUT_PATH" ]; then
    echo "Error: Input file '$INPUT_PATH' not found"
    exit 1
fi

# Check if models directory exists and has content
if [ ! -d "/app/models" ] || [ -z "$(ls -A /app/models 2>/dev/null)" ]; then
    echo "Warning: Models directory is empty. Please mount your model weights to /app/models"
    echo "Expected structure:"
    echo "/app/models/"
    echo "├── Dataset001_TALES/"
    echo "│   ├── nnUNetTrainer__nnUNetPlans__3d_lowres/"
    echo "│   │   └── fold_0/"
    echo "│   │       └── checkpoint_final.pth"
    echo "│   └── nnUNetTrainer__nnUNetPlans__3d_cascade_fullres/"
    echo "│       └── fold_0/"
    echo "│           └── checkpoint_final.pth"
    echo ""
    echo "You can download models from the Google Drive or Hugging Face links in the README"
fi

echo "Starting SALSA liver lesion segmentation pipeline..."
echo "Input: $INPUT_PATH"

# Step 1: Preprocessing with environment 1 (TotalSegmentator + nnUNetv1)
echo "=================================="
echo "Step 1: Preprocessing"
echo "=================================="
conda activate salsa_env1
python /app/codes/SALSA_stepONE_docker.py "$INPUT_PATH"

# Step 2: Inference and postprocessing with environment 2 (nnUNetv2)
echo "=================================="
echo "Step 2: Inference and Postprocessing"
echo "=================================="
conda activate salsa_env2
python /app/codes/SALSA_stepTWO_docker.py "$INPUT_PATH"

echo "=================================="
echo "SALSA pipeline completed successfully!"
echo "=================================="

# Check if processing was successful by looking for output files
FILENAME=$(basename "$INPUT_PATH" | cut -d. -f1)
if [ "${INPUT_PATH##*.}" = "csv" ]; then
    echo "Processed multiple files from CSV. Check output directory for results."
else
    DIRNAME=$(dirname "$INPUT_PATH")
    OUTPUT_FILE="${DIRNAME}/${FILENAME}_SALSA.seg.nrrd"
    if [ -f "$OUTPUT_FILE" ]; then
        echo "Output saved to: $OUTPUT_FILE"
    else
        echo "Warning: Expected output file not found: $OUTPUT_FILE"
    fi
fi