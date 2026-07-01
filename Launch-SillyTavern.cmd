@echo off
title SillyTavern Server
cd /d C:\Users\hayack\Documents\eroAI\SillyTavern
set NODE_ENV=production
echo Starting SillyTavern...
echo URL: http://127.0.0.1:8000/
C:\Users\hayack\Documents\eroAI\ero_ai\.tools\node-v22.23.1-win-x64\node.exe server.js
echo.
echo SillyTavern stopped. Check the messages above.
pause
