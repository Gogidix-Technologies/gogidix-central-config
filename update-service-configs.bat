@echo off
setlocal enabledelayedexpansion

echo =====================================================
echo UPDATING MAVEN CONFIGURATIONS FOR TEST DIRECTORIES
echo =====================================================
echo.

set SERVICES=config-server database-migrations deployment-scripts environment-config infrastructure-as-code kubernetes-manifests regional-deployment

for %%s in (%SERVICES%) do (
    echo.
    echo Processing service: %%s
    echo -----------------------------------------------------
    
    rem Check if pom.xml exists
    if not exist "%%s\pom.xml" (
        echo WARNING: No pom.xml found for %%s, skipping...
        continue
    )
    
    echo 1. Adding REST Assured dependencies to %%s
    
    rem Check if REST Assured is already included
    findstr /c:"io.rest-assured" "%%s\pom.xml" >nul
    if !errorlevel! neq 0 (
        echo Adding REST Assured dependencies...
        
        rem Use PowerShell to add dependencies more reliably
        powershell -Command "(Get-Content '%%s\pom.xml') -replace '([ \t]+</dependencies>)', '        <!-- REST Assured for E2E API Testing -->`n        <dependency>`n            <groupId>io.rest-assured</groupId>`n            <artifactId>rest-assured</artifactId>`n            <version>5.3.0</version>`n            <scope>test</scope>`n        </dependency>`n        `n        <dependency>`n            <groupId>io.rest-assured</groupId>`n            <artifactId>json-path</artifactId>`n            <version>5.3.0</version>`n            <scope>test</scope>`n        </dependency>`n        `n        <dependency>`n            <groupId>io.rest-assured</groupId>`n            <artifactId>xml-path</artifactId>`n            <version>5.3.0</version>`n            <scope>test</scope>`n        </dependency>`n        $1' | Set-Content '%%s\pom.xml'"
    ) else (
        echo REST Assured dependencies already exist, skipping...
    )
    
    echo 2. Adding build-helper-maven-plugin to %%s
    
    rem Check if build-helper-maven-plugin is already included
    findstr /c:"build-helper-maven-plugin" "%%s\pom.xml" >nul
    if !errorlevel! neq 0 (
        echo Adding build-helper-maven-plugin...
        
        rem Use PowerShell to add plugin more reliably
        powershell -Command "(Get-Content '%%s\pom.xml') -replace '(<build>[\r\n \t]+<plugins>)', '$1`n            <!-- Configure build helper plugin to include tests from custom directory structure -->`n            <plugin>`n                <groupId>org.codehaus.mojo</groupId>`n                <artifactId>build-helper-maven-plugin</artifactId>`n                <version>3.3.0</version>`n                <executions>`n                    <execution>`n                        <id>add-test-source</id>`n                        <phase>generate-test-sources</phase>`n                        <goals>`n                            <goal>add-test-source</goal>`n                        </goals>`n                        <configuration>`n                            <sources>`n                                <source>${project.basedir}/tests/unit</source>`n                                <source>${project.basedir}/tests/integration</source>`n                                <source>${project.basedir}/tests/e2e</source>`n                            </sources>`n                        </configuration>`n                    </execution>`n                    <execution>`n                        <id>add-test-resource</id>`n                        <phase>generate-test-resources</phase>`n                        <goals>`n                            <goal>add-test-resource</goal>`n                        </goals>`n                        <configuration>`n                            <resources>`n                                <resource>`n                                    <directory>${project.basedir}/tests</directory>`n                                </resource>`n                            </resources>`n                        </configuration>`n                    </execution>`n                </executions>`n            </plugin>`n            `n            <!-- Configure surefire plugin to run tests -->`n            <plugin>`n                <groupId>org.apache.maven.plugins</groupId>`n                <artifactId>maven-surefire-plugin</artifactId>`n                <version>3.1.2</version>`n                <configuration>`n                    <includes>`n                        <include>**/*Test.java</include>`n                    </includes>`n                </configuration>`n            </plugin>' | Set-Content '%%s\pom.xml'"
    ) else (
        echo build-helper-maven-plugin already exists, skipping...
    )
    
    echo Completed configuration updates for %%s
)

echo.
echo =====================================================
echo CONFIGURATION UPDATE COMPLETE
echo =====================================================
echo.
echo All services have been updated with:
echo 1. REST Assured dependencies for E2E testing
echo 2. build-helper-maven-plugin for custom test directories
echo 3. maven-surefire-plugin configuration for test patterns
echo.
echo You can now run all tests using:
echo   mvn clean test
echo or
echo   .\verify-tests.bat
echo =====================================================
