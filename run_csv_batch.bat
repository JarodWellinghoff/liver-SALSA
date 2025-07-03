@echo off 
if "%1"=="" ( 
    echo Usage: run_csv_batch.bat csv_filename.csv 
    echo Example: run_csv_batch.bat scans.csv 
    pause 
    exit /b 1 
) 
docker-compose run --rm salsa /app/data/%1 
