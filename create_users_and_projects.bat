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
    echo Creating user !USERNAME!

    REM Create user
    for /f "tokens=2 delims=:" %%A in ('
        curl -s -X POST "%GITLAB_URL%/api/v4/users" ^
          -H "PRIVATE-TOKEN: %GITLAB_TOKEN%" ^
          -H "Content-Type: application/json" ^
          -d "{\"email\":\"!EMAIL!\",\"username\":\"!USERNAME!\",\"name\":\"!NAME!\",\"password\":\"!PASSWORD!\",\"skip_confirmation\":true}"
    ') do (
        set RAW=%%A
        goto got_id
    )

    :got_id
    set USER_ID=!RAW:,=!
    set USER_ID=!USER_ID:}=!

    if "!USER_ID!"=="" (
        echo FAILED to create user !USERNAME!
        echo.
    ) else (
        echo User ID = !USER_ID!

        REM Create project owned by user
        curl -s -X POST "%GITLAB_URL%/api/v4/projects" ^
          -H "PRIVATE-TOKEN: %GITLAB_TOKEN%" ^
          -H "Content-Type: application/json" ^
          -d "{\"name\":\"!USERNAME!\",\"namespace_id\":!USER_ID!,\"visibility\":\"public\"}"

        echo.
    )
)

echo DONE
pause
