@echo off
echo === Running Tests for Central Configuration Services ===

cd %~dp0
set PROJECT_ROOT=%CD%
set SUCCESS=0
set FAILED_SERVICES=

echo.
echo === Testing config-server ===
cd %PROJECT_ROOT%\config-server
call mvn clean test
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] config-server tests failed!
    set FAILED_SERVICES=%FAILED_SERVICES% config-server
    set SUCCESS=1
) else (
    echo [SUCCESS] config-server tests passed!
)

echo.
echo === Testing database-migrations ===
cd %PROJECT_ROOT%\database-migrations
call mvn clean test
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] database-migrations tests failed!
    set FAILED_SERVICES=%FAILED_SERVICES% database-migrations
    set SUCCESS=1
) else (
    echo [SUCCESS] database-migrations tests passed!
)

echo.
echo === Testing deployment-scripts ===
cd %PROJECT_ROOT%\deployment-scripts
call mvn clean test
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] deployment-scripts tests failed!
    set FAILED_SERVICES=%FAILED_SERVICES% deployment-scripts
    set SUCCESS=1
) else (
    echo [SUCCESS] deployment-scripts tests passed!
)

echo.
echo === Testing disaster-recovery ===
cd %PROJECT_ROOT%\disaster-recovery
call mvn clean test
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] disaster-recovery tests failed!
    set FAILED_SERVICES=%FAILED_SERVICES% disaster-recovery
    set SUCCESS=1
) else (
    echo [SUCCESS] disaster-recovery tests passed!
)

echo.
echo === Testing environment-config ===
cd %PROJECT_ROOT%\environment-config
call mvn clean test
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] environment-config tests failed!
    set FAILED_SERVICES=%FAILED_SERVICES% environment-config
    set SUCCESS=1
) else (
    echo [SUCCESS] environment-config tests passed!
)

echo.
echo === Testing infrastructure-as-code ===
cd %PROJECT_ROOT%\infrastructure-as-code
call mvn clean test
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] infrastructure-as-code tests failed!
    set FAILED_SERVICES=%FAILED_SERVICES% infrastructure-as-code
    set SUCCESS=1
) else (
    echo [SUCCESS] infrastructure-as-code tests passed!
)

echo.
echo === Testing kubernetes-manifests ===
cd %PROJECT_ROOT%\kubernetes-manifests
call mvn clean test
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] kubernetes-manifests tests failed!
    set FAILED_SERVICES=%FAILED_SERVICES% kubernetes-manifests
    set SUCCESS=1
) else (
    echo [SUCCESS] kubernetes-manifests tests passed!
)

echo.
echo === Testing regional-deployment ===
cd %PROJECT_ROOT%\regional-deployment
call mvn clean test
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] regional-deployment tests failed!
    set FAILED_SERVICES=%FAILED_SERVICES% regional-deployment
    set SUCCESS=1
) else (
    echo [SUCCESS] regional-deployment tests passed!
)

echo.
echo === Testing secrets-management ===
cd %PROJECT_ROOT%\secrets-management
call mvn clean test
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] secrets-management tests failed!
    set FAILED_SERVICES=%FAILED_SERVICES% secrets-management
    set SUCCESS=1
) else (
    echo [SUCCESS] secrets-management tests passed!
)

echo.
echo === Test Summary ===
if %SUCCESS% EQU 0 (
    echo All tests passed successfully! Ready to deploy to GitHub.
) else (
    echo [WARNING] Tests failed for:%FAILED_SERVICES%
    echo Please fix the failing tests before deploying to GitHub.
)

cd %PROJECT_ROOT%
