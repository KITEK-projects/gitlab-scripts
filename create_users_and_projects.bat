@echo off
setlocal EnableDelayedExpansion

REM ==============================
REM CONFIG
REM ==============================
set GITLAB_URL=http://localhost
set GITLAB_TOKEN=PASTE_YOUR_ADMIN_TOKEN_HERE
set USER_COUNT=10

REM ==============================
REM MAIN LOOP
REM ==============================
for /L %%i in (1,1,%USER_COUNT%) do (

    set USERNAME=user%%i
    set EMAIL=user%%i@user%%i.ru
    set NAME=user%%i@user%%i.ru
    set PASSWORD=omsktec%%i

    echo ----------------------------------------
    echo Creating user !USERNAME! with password !PASSWORD!

    REM Create user and capture response
    for /f "delims=" %%R in ('
        curl -s -X POST "%GITLAB_URL%/api/v4/users" ^
            -H "PRIVATE-TOKEN: %GITLAB_TOKEN%" ^
            -H "Content-Type: application/json" ^
            -d "{\"email\":\"!EMAIL!\",\"username\":\"!USERNAME!\",\"name\":\"!NAME!\",\"password\":\"!PASSWORD!\",\"skip_confirmation\":true}"
    ') do set RESPONSE=%%R

    REM Extract user ID using PowerShell
    for /f %%U in ('
        echo !RESPONSE! ^| powershell -Command "(ConvertFrom-Json (Get-Content -Raw)).id"
    ') do set USER_ID=%%U

    if "!USER_ID!"=="" (
        echo FAILED to create user !USERNAME!
        echo Response: !RESPONSE!
        echo.
        goto :continue
    )

    echo User ID = !USER_ID!

    REM Create public project owned by this user
    echo Creating project !USERNAME! for user !USERNAME!

    curl -s -X POST "%GITLAB_URL%/api/v4/projects" ^
        -H "PRIVATE-TOKEN: %GITLAB_TOKEN%" ^
        -H "Content-Type: application/json" ^
        -d "{\"name\":\"!USERNAME!\",\"namespace_id\":!USER_ID!,\"visibility\":\"public\"}"

    echo.
    :continue
)

echo ALL USERS AND PROJECTS CREATED
pause

