@echo off
echo === Updating Test Configurations for Central Configuration Services ===

cd %~dp0
set PROJECT_ROOT=%CD%

for %%s in (config-server database-migrations deployment-scripts disaster-recovery environment-config infrastructure-as-code kubernetes-manifests regional-deployment secrets-management) do (
    echo Updating %%s POM file...
    cd %PROJECT_ROOT%\%%s
    
    REM Update the pom.xml to include the custom test directories
    if exist "pom.xml" (
        powershell -Command "(gc pom.xml) -replace '<artifactId>maven-surefire-plugin</artifactId>(\r?\n +)<version>[^<]+</version>', '<artifactId>maven-surefire-plugin</artifactId>$1<version>3.1.2</version>$1<configuration>$1    <testSourceDirectory>${project.basedir}/tests</testSourceDirectory>$1    <testResources>$1        <testResource>$1            <directory>${project.basedir}/tests</directory>$1        </testResource>$1    </testResources>$1</configuration>'" | Out-File -Encoding UTF8 pom.xml.new
        move /y pom.xml.new pom.xml
    )
)

echo.
echo Configuration update completed. You can now run the tests.
echo.

cd %PROJECT_ROOT%
