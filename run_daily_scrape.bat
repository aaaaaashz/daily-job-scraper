@echo off
setlocal
cd /d "%~dp0"
.venv\Scripts\python.exe -m scraper.main run
exit /b %ERRORLEVEL%
