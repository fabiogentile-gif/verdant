@echo off
rem Works from any folder: always runs inside the backend directory.
cd /d "%~dp0"
echo Starting Verdant Backend API...
echo Server will be available at http://localhost:3000
npm run dev
