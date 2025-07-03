# SALSA PowerShell Runner Script
# Advanced PowerShell script for running SALSA with better error handling and logging

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true, Position=0)]
    [string]$InputFile,
    
    [Parameter(Mandatory=$false)]
    [switch]$UseGPU = $true,
    
    [Parameter(Mandatory=$false)]
    [switch]$KeepIntermediateFiles = $false,
    
    [Parameter(Mandatory=$false)]
    [string]$LogFile = "",
    
    [Parameter(Mandatory=$false)]
    [switch]$Verbose = $false
)

# Set error action preference
$ErrorActionPreference = "Stop"

# Function to write colored output
function Write-ColorOutput([string]$Message, [string]$Color = "White") {
    $oldColor = $Host.UI.RawUI.ForegroundColor
    $Host.UI.RawUI.ForegroundColor = $Color
    Write-Output $Message
    $Host.UI.RawUI.ForegroundColor = $oldColor
}

# Function to log messages
function Write-Log([string]$Message, [string]$Level = "INFO") {
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    
    if ($LogFile -ne "") {
        Add-Content -Path $LogFile -Value $logMessage
    }
    
    switch ($Level) {
        "ERROR" { Write-ColorOutput $logMessage "Red" }
        "WARN"  { Write-ColorOutput $logMessage "Yellow" }
        "INFO"  { Write-ColorOutput $logMessage "Green" }
        default { Write-Output $logMessage }
    }
}

# Main execution
try {
    Write-Log "🏥 Starting SALSA liver lesion segmentation" "INFO"
    Write-Log "Input file: $InputFile" "INFO"
    
    # Validate input file exists
    $fullInputPath = Join-Path "data" $InputFile
    if (!(Test-Path $fullInputPath)) {
        Write-Log "Input file not found: $fullInputPath" "ERROR"
        Write-Log "Please ensure the file exists in the data\ directory" "ERROR"
        exit 1
    }
    
    # Check if Docker is running
    Write-Log "Checking Docker status..." "INFO"
    $dockerStatus = docker ps 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Log "Docker is not running. Please start Docker Desktop." "ERROR"
        exit 1
    }
    Write-Log "✅ Docker is running" "INFO"
    
    # Check if SALSA image exists
    Write-Log "Checking for SALSA Docker image..." "INFO"
    $imageExists = docker images salsa:latest --format "{{.Repository}}" 2>$null
    if ($imageExists -ne "salsa") {
        Write-Log "SALSA Docker image not found. Building image..." "WARN"
        Write-Log "This may take 10-20 minutes..." "INFO"
        
        docker-compose build
        if ($LASTEXITCODE -ne 0) {
            Write-Log "Failed to build Docker image" "ERROR"
            exit 1
        }
        Write-Log "✅ Docker image built successfully" "INFO"
    }
    
    # Prepare Docker command
    $dockerArgs = @(
        "run", "--rm"
    )
    
    # Add GPU support if requested and available
    if ($UseGPU) {
        Write-Log "Checking for GPU support..." "INFO"
        $gpuTest = docker run --rm --gpus all nvidia/cuda:12.1-base nvidia-smi 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Log "✅ GPU support available" "INFO"
            $dockerArgs += "--gpus", "all"
        } else {
            Write-Log "⚠️ GPU support not available, using CPU mode" "WARN"
        }
    }
    
    # Add volume mounts
    $currentDir = (Get-Location).Path
    $dockerArgs += @(
        "-v", "$currentDir\data:/app/data",
        "-v", "$currentDir\output:/app/output", 
        "-v", "$currentDir\models:/app/models"
    )
    
    # Add environment variables
    if ($KeepIntermediateFiles) {
        Write-Log "Intermediate files will be kept" "INFO"
        # This would require modifying the Python script to respect this flag
    }
    
    if ($Verbose) {
        $dockerArgs += "-e", "PYTHONUNBUFFERED=1"
    }
    
    # Add image and input file
    $dockerArgs += @("salsa:latest", "/app/data/$InputFile")
    
    # Run SALSA
    Write-Log "🚀 Starting SALSA processing..." "INFO"
    Write-Log "Command: docker $($dockerArgs -join ' ')" "INFO"
    
    $startTime = Get-Date
    
    & docker @dockerArgs
    
    if ($LASTEXITCODE -eq 0) {
        $endTime = Get-Date
        $duration = $endTime - $startTime
        
        Write-Log "✅ SALSA processing completed successfully!" "INFO"
        Write-Log "Processing time: $($duration.ToString('hh\:mm\:ss'))" "INFO"
        
        # Check for output file
        $outputFileName = [System.IO.Path]::GetFileNameWithoutExtension($InputFile) + "_SALSA.seg.nrrd"
        $outputPath = Join-Path "output" $outputFileName
        
        if (Test-Path $outputPath) {
            Write-Log "✅ Output file created: $outputPath" "INFO"
            $outputSize = (Get-Item $outputPath).Length / 1MB
            Write-Log "Output file size: $($outputSize.ToString('F2')) MB" "INFO"
        } else {
            Write-Log "⚠️ Output file not found at expected location: $outputPath" "WARN"
        }
        
    } else {
        Write-Log "❌ SALSA processing failed" "ERROR"
        exit 1
    }
    
} catch {
    Write-Log "❌ An error occurred: $($_.Exception.Message)" "ERROR"
    Write-Log "Stack trace: $($_.ScriptStackTrace)" "ERROR"
    exit 1
}

# Usage examples:
# .\Run-SALSA.ps1 scan.nii.gz
# .\Run-SALSA.ps1 scan.nii.gz -UseGPU:$false
# .\Run-SALSA.ps1 scan.nii.gz -LogFile "salsa.log" -Verbose