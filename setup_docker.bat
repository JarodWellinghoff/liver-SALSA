@echo off
REM SALSA Docker Setup Script for Windows
REM This script helps set up the SALSA Docker environment on Windows

echo 🏥 SALSA Docker Setup Script (Windows)
echo ==================================

REM Check if Docker is installed
docker --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Docker is not installed. Please install Docker Desktop first.
    echo Visit: https://docs.docker.com/desktop/windows/
    pause
    exit /b 1
)

REM Check if Docker Compose is installed
docker compose version >nul 2>&1
if %errorlevel% neq 0 (
    docker-compose --version >nul 2>&1
    if %errorlevel% neq 0 (
        echo ❌ Docker Compose is not available.
        echo Please ensure Docker Desktop is properly installed.
        pause
        exit /b 1
    )
)

echo ✅ Docker and Docker Compose are installed

REM Check if Docker Desktop is running
docker ps >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Docker Desktop is not running. Please start Docker Desktop first.
    pause
    exit /b 1
)

echo ✅ Docker Desktop is running

REM Check for WSL2 backend (recommended for Windows)
docker system info | find "WSL" >nul 2>&1
if %errorlevel% equ 0 (
    echo ✅ Using WSL2 backend (recommended)
) else (
    echo ⚠️  Not using WSL2 backend. Consider switching to WSL2 for better performance.
    echo   Go to Docker Desktop Settings → General → Use WSL2 based engine
)

REM Check for GPU support (Windows specific)
nvidia-smi >nul 2>&1
if %errorlevel% equ 0 (
    echo ✅ NVIDIA GPU detected
    echo ℹ️  Note: GPU support in Docker on Windows requires:
    echo    - Docker Desktop with WSL2 backend
    echo    - NVIDIA Container Toolkit installed in WSL2
    echo    - See README_Docker_Windows.md for setup instructions
) else (
    echo ℹ️  No NVIDIA GPU detected - will use CPU mode
)

echo.
echo 📁 Creating directory structure...
if not exist "data" mkdir data
if not exist "output" mkdir output
if not exist "models" mkdir models

echo ✅ Created directories:
echo    - data\    (place your NIfTI files here)
echo    - output\  (segmentation results will appear here)
echo    - models\  (place downloaded model weights here)

REM Copy the modified Python files to replace the originals
echo.
echo 📝 Setting up modified code for Docker...
if exist "codes\SALSA_stepONE_docker.py" (
    copy "codes\SALSA_stepONE_docker.py" "codes\SALSA_stepONE.py" >nul
    echo ✅ Updated SALSA_stepONE.py for Docker
)

if exist "codes\SALSA_stepTWO_docker.py" (
    copy "codes\SALSA_stepTWO_docker.py" "codes\SALSA_stepTWO.py" >nul
    echo ✅ Updated SALSA_stepTWO.py for Docker
)

REM Check if models exist
echo.
echo 🔍 Checking for model weights...
if exist "models\Dataset001_TALES" (
    echo ✅ Model weights found
) else (
    echo ⚠️  Model weights not found!
    echo.
    echo 📥 Please download the model weights:
    echo    1. Download from Google Drive or Hugging Face (see README)
    echo    2. Extract and place in models\ directory
    echo    3. Structure should be:
    echo       models\
    echo       └── Dataset001_TALES\
    echo           ├── nnUNetTrainer__nnUNetPlans__3d_lowres\
    echo           │   └── fold_0\
    echo           │       └── checkpoint_final.pth
    echo           └── nnUNetTrainer__nnUNetPlans__3d_cascade_fullres\
    echo               └── fold_0\
    echo                   └── checkpoint_final.pth
)

REM Build Docker image
echo.
echo 🐳 Building Docker image...
echo    This may take 10-20 minutes on first build...

docker compose build
if %errorlevel% neq 0 (
    echo ❌ Docker build failed. Check error messages above.
    pause
    exit /b 1
)

echo.
echo ✅ Docker image built successfully!

REM Create example CSV file
echo.
echo 📄 Creating example CSV file...
echo PATHS > data\example_scans.csv
echo /app/data/scan1.nii.gz >> data\example_scans.csv
echo /app/data/scan2.nii.gz >> data\example_scans.csv

echo ✅ Created data\example_scans.csv

REM Create Windows batch files for easy execution
echo.
echo 📝 Creating Windows convenience scripts...

echo @echo off > run_single_scan.bat
echo if "%%1"=="" ( >> run_single_scan.bat
echo     echo Usage: run_single_scan.bat scan_filename.nii.gz >> run_single_scan.bat
echo     echo Example: run_single_scan.bat scan.nii.gz >> run_single_scan.bat
echo     pause >> run_single_scan.bat
echo     exit /b 1 >> run_single_scan.bat
echo ^) >> run_single_scan.bat
echo docker-compose run --rm salsa /app/data/%%1 >> run_single_scan.bat

echo @echo off > run_csv_batch.bat
echo if "%%1"=="" ( >> run_csv_batch.bat
echo     echo Usage: run_csv_batch.bat csv_filename.csv >> run_csv_batch.bat
echo     echo Example: run_csv_batch.bat scans.csv >> run_csv_batch.bat
echo     pause >> run_csv_batch.bat
echo     exit /b 1 >> run_csv_batch.bat
echo ^) >> run_csv_batch.bat
echo docker-compose run --rm salsa /app/data/%%1 >> run_csv_batch.bat

echo ✅ Created convenience scripts:
echo    - run_single_scan.bat
echo    - run_csv_batch.bat

REM Show usage examples
echo.
echo 🚀 Setup complete! Usage examples:
echo.
echo 1. Process a single scan (using convenience script):
echo    run_single_scan.bat your_scan.nii.gz
echo.
echo 2. Process a single scan (using docker-compose):
echo    docker-compose run --rm salsa /app/data/your_scan.nii.gz
echo.
echo 3. Process multiple scans from CSV:
echo    run_csv_batch.bat example_scans.csv
echo.
echo 4. Interactive mode (for debugging):
echo    docker-compose run --rm --entrypoint /bin/bash salsa
echo.
echo 📖 For more information, see README_Docker_Windows.md
echo.
echo 🎉 Ready to segment liver lesions with SALSA on Windows!
echo.
pause