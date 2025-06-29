@echo off
echo === Adding Test Dependencies to All Modules ===

cd %~dp0
set PROJECT_ROOT=%CD%

echo.
echo === Creating dependency template file ===
echo ^<dependencies^> > dependencies-template.xml
echo     ^<!-- REST Assured for E2E API Testing --^> >> dependencies-template.xml
echo     ^<dependency^> >> dependencies-template.xml
echo         ^<groupId^>io.rest-assured^</groupId^> >> dependencies-template.xml
echo         ^<artifactId^>rest-assured^</artifactId^> >> dependencies-template.xml
echo         ^<version^>5.3.0^</version^> >> dependencies-template.xml
echo         ^<scope^>test^</scope^> >> dependencies-template.xml
echo     ^</dependency^> >> dependencies-template.xml
echo. >> dependencies-template.xml
echo     ^<dependency^> >> dependencies-template.xml
echo         ^<groupId^>io.rest-assured^</groupId^> >> dependencies-template.xml
echo         ^<artifactId^>json-path^</artifactId^> >> dependencies-template.xml
echo         ^<version^>5.3.0^</version^> >> dependencies-template.xml
echo         ^<scope^>test^</scope^> >> dependencies-template.xml
echo     ^</dependency^> >> dependencies-template.xml
echo. >> dependencies-template.xml
echo     ^<dependency^> >> dependencies-template.xml
echo         ^<groupId^>io.rest-assured^</groupId^> >> dependencies-template.xml
echo         ^<artifactId^>xml-path^</artifactId^> >> dependencies-template.xml
echo         ^<version^>5.3.0^</version^> >> dependencies-template.xml
echo         ^<scope^>test^</scope^> >> dependencies-template.xml
echo     ^</dependency^> >> dependencies-template.xml
echo ^</dependencies^> >> dependencies-template.xml

echo.
echo === Creating plugins template file ===
echo ^<plugin^> > plugins-template.xml
echo     ^<groupId^>org.codehaus.mojo^</groupId^> >> plugins-template.xml
echo     ^<artifactId^>build-helper-maven-plugin^</artifactId^> >> plugins-template.xml
echo     ^<version^>3.3.0^</version^> >> plugins-template.xml
echo     ^<executions^> >> plugins-template.xml
echo         ^<execution^> >> plugins-template.xml
echo             ^<id^>add-test-source^</id^> >> plugins-template.xml
echo             ^<phase^>generate-test-sources^</phase^> >> plugins-template.xml
echo             ^<goals^> >> plugins-template.xml
echo                 ^<goal^>add-test-source^</goal^> >> plugins-template.xml
echo             ^</goals^> >> plugins-template.xml
echo             ^<configuration^> >> plugins-template.xml
echo                 ^<sources^> >> plugins-template.xml
echo                     ^<source^>${project.basedir}/tests/unit^</source^> >> plugins-template.xml
echo                     ^<source^>${project.basedir}/tests/integration^</source^> >> plugins-template.xml
echo                     ^<source^>${project.basedir}/tests/e2e^</source^> >> plugins-template.xml
echo                 ^</sources^> >> plugins-template.xml
echo             ^</configuration^> >> plugins-template.xml
echo         ^</execution^> >> plugins-template.xml
echo         ^<execution^> >> plugins-template.xml
echo             ^<id^>add-test-resource^</id^> >> plugins-template.xml
echo             ^<phase^>generate-test-resources^</phase^> >> plugins-template.xml
echo             ^<goals^> >> plugins-template.xml
echo                 ^<goal^>add-test-resource^</goal^> >> plugins-template.xml
echo             ^</goals^> >> plugins-template.xml
echo             ^<configuration^> >> plugins-template.xml
echo                 ^<resources^> >> plugins-template.xml
echo                     ^<resource^> >> plugins-template.xml
echo                         ^<directory^>${project.basedir}/tests^</directory^> >> plugins-template.xml
echo                     ^</resource^> >> plugins-template.xml
echo                 ^</resources^> >> plugins-template.xml
echo             ^</configuration^> >> plugins-template.xml
echo         ^</execution^> >> plugins-template.xml
echo     ^</executions^> >> plugins-template.xml
echo ^</plugin^> >> plugins-template.xml

echo.
echo === Creating surefire template file ===
echo ^<plugin^> > surefire-template.xml
echo     ^<groupId^>org.apache.maven.plugins^</groupId^> >> surefire-template.xml
echo     ^<artifactId^>maven-surefire-plugin^</artifactId^> >> surefire-template.xml
echo     ^<version^>3.1.2^</version^> >> surefire-template.xml
echo     ^<configuration^> >> surefire-template.xml
echo         ^<includes^> >> surefire-template.xml
echo             ^<include^>**/*Test.java^</include^> >> surefire-template.xml
echo         ^</includes^> >> surefire-template.xml
echo     ^</configuration^> >> surefire-template.xml
echo ^</plugin^> >> surefire-template.xml

echo.
echo === Now updating each module ===
for %%s in (config-server database-migrations deployment-scripts disaster-recovery environment-config infrastructure-as-code kubernetes-manifests regional-deployment secrets-management) do (
    echo.
    echo === Processing %%s ===
    cd %PROJECT_ROOT%\%%s
    
    if exist "pom.xml" (
        echo Updating dependencies in %%s
        powershell -Command "$content = Get-Content -Path 'pom.xml' -Raw; $depsTemplate = Get-Content -Path '%PROJECT_ROOT%\dependencies-template.xml' -Raw; if ($content -notmatch 'io.rest-assured') { $content = $content -replace '</dependencies>', \"$depsTemplate\r\n    </dependencies>\" }; $content | Set-Content -Path 'pom.xml' -Encoding UTF8"
        
        echo Updating build plugins in %%s
        powershell -Command "$content = Get-Content -Path 'pom.xml' -Raw; $pluginsTemplate = Get-Content -Path '%PROJECT_ROOT%\plugins-template.xml' -Raw; $surefireTemplate = Get-Content -Path '%PROJECT_ROOT%\surefire-template.xml' -Raw; if ($content -notmatch 'build-helper-maven-plugin') { $content = $content -replace '<plugin>\s*<groupId>org.apache.maven.plugins</groupId>\s*<artifactId>maven-surefire-plugin</artifactId>', \"$surefireTemplate\r\n            $pluginsTemplate\r\n            <plugin>\r\n                <groupId>org.apache.maven.plugins</groupId>\r\n                <artifactId>maven-surefire-plugin</artifactId>\" }; $content | Set-Content -Path 'pom.xml' -Encoding UTF8"
        
        echo %%s updated successfully
    ) else (
        echo WARNING: No pom.xml found in %%s
    )
)

echo.
echo === Cleaning up template files ===
del dependencies-template.xml
del plugins-template.xml
del surefire-template.xml

echo.
echo === Update completed ===
echo You should now be able to run tests for all modules.
echo To run a specific module's tests: cd module-name ^&^& mvn clean test
echo To run all tests from the parent directory: mvn clean test

cd %PROJECT_ROOT%
