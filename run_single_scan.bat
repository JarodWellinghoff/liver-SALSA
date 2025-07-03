@echo off 
if "%1"=="" ( 
    echo Usage: run_single_scan.bat scan_filename.nii.gz 
    echo Example: run_single_scan.bat scan.nii.gz 
    pause 
    exit /b 1 
) 
docker-compose run --rm salsa /app/data/%1 
