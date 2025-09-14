@echo off
pushd "%~dp0"

REM Pobierz aktualną datę i czas w formacie YYYYMMDD_HHMM
for /f "tokens=2 delims==" %%a in ('wmic OS Get localdatetime /value') do set datetime=%%a
set TIMESTAMP=%datetime:~0,8%_%datetime:~8,4%

REM Ustaw nazwy plików
if "%BUILD_TYPE%"=="debug" (
    set OLD_NAME=app-debug.apk
    set NEW_NAME=HTTP_Request_Generator_debug_%TIMESTAMP%.apk
) else (
    set OLD_NAME=app-release.apk
    set NEW_NAME=HTTP_Request_Generator_release_%TIMESTAMP%.apk
)

REM Zmień nazwę pliku
echo [4/4] Renaming APK file...
if exist "build\app\outputs\flutter-apk\%OLD_NAME%" (
    ren "build\app\outputs\flutter-apk\%OLD_NAME%" "%NEW_NAME%"
    echo.
    echo ========================================
    echo SUCCESS! APK built and renamed!
    echo ========================================
    echo Old name: %OLD_NAME%
    echo New name: %NEW_NAME%
    echo Location: build\app\outputs\flutter-apk\
    echo Full path: %CD%\build\app\outputs\flutter-apk\%NEW_NAME%
    echo ========================================
) else (
    echo ERROR: APK file not found at expected location!
    echo Looking for: build\app\outputs\flutter-apk\%OLD_NAME%
    goto :error
)


popd