@echo off
cd /d C:\Users\Simon
echo Rebuilding the broker with the browser door (port 9001)...
docker compose up -d --build mqtt
echo.
echo --- Config inside the running broker ---
docker exec openmoxie-mqtt cat /mosquitto/config/mosquitto.conf
echo.
echo If you can see "listener 9001" above, open the sim page and tap Connect.
pause
