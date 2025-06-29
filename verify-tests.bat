@echo off
setlocal enabledelayedexpansion

echo =====================================================
echo CENTRAL CONFIGURATION MICROSERVICES TEST VERIFICATION
echo =====================================================
echo.

set SERVICES=config-server database-migrations deployment-scripts disaster-recovery environment-config infrastructure-as-code kubernetes-manifests regional-deployment secrets-management

set FAILED_SERVICES=
set PASSED_SERVICES=
set ALL_PASSED=true

for %%s in (%SERVICES%) do (
    echo.
    echo -----------------------------------------------------
    echo Testing Service: %%s
    echo -----------------------------------------------------
    
    pushd %%s
    
    echo Running tests with detailed output...
    call mvn clean test -Dsurefire.printSummary=true -B -Dorg.slf4j.simpleLogger.log.org.apache.maven.cli.transfer.Slf4jMavenTransferListener=warn
    
    if !ERRORLEVEL! NEQ 0 (
        echo [FAILED] Service %%s tests failed
        set FAILED_SERVICES=!FAILED_SERVICES! %%s
        set ALL_PASSED=false
    ) else (
        echo [SUCCESS] Service %%s tests passed
        set PASSED_SERVICES=!PASSED_SERVICES! %%s
    )
    
    popd
)

echo.
echo =====================================================
echo TEST RESULTS SUMMARY
echo =====================================================
echo.

if "%ALL_PASSED%"=="true" (
    echo [SUCCESS] All tests passed successfully!
    echo.
    echo Services with passing tests:
    for %%s in (%PASSED_SERVICES%) do (
        echo - %%s
    )
) else (
    echo [FAILED] Some tests failed!
    echo.
    echo Services with passing tests:
    for %%s in (%PASSED_SERVICES%) do (
        echo - %%s
    )
    echo.
    echo Services with failing tests:
    for %%s in (%FAILED_SERVICES%) do (
        echo - %%s
    )
    echo.
    echo Please fix the failing tests before proceeding with Git deployment.
)

echo.
echo =====================================================

if "%ALL_PASSED%"=="true" (
    exit /b 0
) else (
    exit /b 1
)
