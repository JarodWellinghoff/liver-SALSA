FROM nvidia/cuda:12.4.1-devel-ubuntu22.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1
ENV CONDA_DIR=/opt/conda
ENV PATH=$CONDA_DIR/bin:$PATH

# Install system dependencies
RUN apt-get update && apt-get install -y \
    wget \
    bzip2 \
    ca-certificates \
    curl \
    git \
    && rm -rf /var/lib/apt/lists/*

# Install Miniconda
RUN wget --quiet https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ~/miniconda.sh && \
    /bin/bash ~/miniconda.sh -b -p $CONDA_DIR && \
    rm ~/miniconda.sh && \
    conda clean -ay

# Create working directory
WORKDIR /app

# Copy requirements files first for better caching
COPY requirements1.txt requirements2.txt ./

# Create first environment (for preprocessing with TotalSegmentator)
RUN conda create --name salsa_env1 python=3.10 -y && \
    conda run -n salsa_env1 pip install --no-cache-dir -r requirements1.txt

# Create second environment (for inference with nnUNetv2)
RUN conda create --name salsa_env2 python=3.10 -y && \
    conda run -n salsa_env2 pip install --no-cache-dir -r requirements2.txt

# Copy source code
COPY codes/ ./codes/
COPY README.md license.txt ./

# Create directories for models and data
RUN mkdir -p /app/models /app/data /app/output

# Set up TotalSegmentator weights directory
RUN mkdir -p /root/.totalsegmentator/nnunet/results/nnUNet/3d_fullres/

# Create entrypoint script
COPY docker-entrypoint.sh /app/
RUN chmod +x /app/docker-entrypoint.sh

# Set environment variables for model paths
ENV NNUNET_RESULTS=/app/models
ENV TOTALSEGMENTATOR_WEIGHTS=/root/.totalsegmentator/nnunet/results/nnUNet/3d_fullres/

# Expose volume mount points
VOLUME ["/app/data", "/app/output", "/app/models"]

ENTRYPOINT ["/app/docker-entrypoint.sh"]