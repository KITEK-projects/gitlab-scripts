
@echo off
setlocal EnableDelayedExpansion

REM ==============================
REM CONFIG
REM ==============================
set GITLAB_URL=http://localhost
set ADMIN_TOKEN=PASTE_ADMIN_TOKEN_HERE
set USER_COUNT=10

REM ==============================
REM MAIN LOOP
REM ==============================
for /L %%i in (1,1,%USER_COUNT%) do (

    set USERNAME=user%%i
    set EMAIL=user%%i@user%%i.ru
    set NAME=user%%i@user%%i.ru
    set PASSWORD=omsktec%%i
    set TOKEN_NAME=auto-token

    echo ----------------------------------------
    echo Creating user !USERNAME!

    REM 1. Create user
    curl -s -X POST "%GITLAB_URL%/api/v4/users" ^
        -H "PRIVATE-TOKEN: %ADMIN_TOKEN%" ^
        -H "Content-Type: application/json" ^
        -d "{\"email\":\"!EMAIL!\",\"username\":\"!USERNAME!\",\"name\":\"!NAME!\",\"password\":\"!PASSWORD!\",\"skip_confirmation\":true}"

    REM 2. Get user ID
    for /f "tokens=2 delims=:" %%U in ('
        curl -s -H "PRIVATE-TOKEN: %ADMIN_TOKEN%" "%GITLAB_URL%/api/v4/users?username=!USERNAME!"
    ') do (
        set USER_ID=%%U
        goto got_user
    )

    :got_user
    set USER_ID=!USER_ID:,=!
    set USER_ID=!USER_ID:}=!

    if "!USER_ID!"=="" (
        echo FAILED to get user ID
        echo.
        goto next
    )

    echo User ID = !USER_ID!

    REM 3. Create PAT for user
    for /f "tokens=2 delims=:" %%T in ('
        curl -s -X POST "%GITLAB_URL%/api/v4/users/!USER_ID!/personal_access_tokens" ^
          -H "PRIVATE-TOKEN: %ADMIN_TOKEN%" ^
          -H "Content-Type: application/json" ^
          -d "{\"name\":\"!TOKEN_NAME!\",\"scopes\":[\"api\"]}"
    ') do (
        set USER_TOKEN=%%T
        goto got_token
    )

    :got_token
    set USER_TOKEN=!USER_TOKEN:,=!
    set USER_TOKEN=!USER_TOKEN:}=!

    if "!USER_TOKEN!"=="" (
        echo FAILED to create user token
        echo.
        goto next
    )

    echo Token created for !USERNAME!

    REM 4. Create project AS USER
    echo Creating project !USERNAME! as !USERNAME!

    curl -s -X POST "%GITLAB_URL%/api/v4/projects" ^
        -H "PRIVATE-TOKEN: !USER_TOKEN!" ^
        -H "Content-Type: application/json" ^
        -d "{\"name\":\"!USERNAME!\",\"visibility\":\"public\"}"

    echo.
    :next
)

echo DONE
pause
