Write-Host "Updating Maven configurations for all central-configuration microservices..."

$projectRoot = $PSScriptRoot
$services = @(
    "config-server",
    "database-migrations", 
    "deployment-scripts",
    "disaster-recovery",
    "environment-config",
    "infrastructure-as-code",
    "kubernetes-manifests",
    "regional-deployment",
    "secrets-management"
)

$buildHelperPlugin = @"
            <!-- Configure build helper plugin to include tests from custom directory structure -->
            <plugin>
                <groupId>org.codehaus.mojo</groupId>
                <artifactId>build-helper-maven-plugin</artifactId>
                <version>3.3.0</version>
                <executions>
                    <execution>
                        <id>add-test-source</id>
                        <phase>generate-test-sources</phase>
                        <goals>
                            <goal>add-test-source</goal>
                        </goals>
                        <configuration>
                            <sources>
                                <source>\${project.basedir}/tests/unit</source>
                                <source>\${project.basedir}/tests/integration</source>
                                <source>\${project.basedir}/tests/e2e</source>
                            </sources>
                        </configuration>
                    </execution>
                    <execution>
                        <id>add-test-resource</id>
                        <phase>generate-test-resources</phase>
                        <goals>
                            <goal>add-test-resource</goal>
                        </goals>
                        <configuration>
                            <resources>
                                <resource>
                                    <directory>\${project.basedir}/tests</directory>
                                </resource>
                            </resources>
                        </configuration>
                    </execution>
                </executions>
            </plugin>
"@

$surefirePlugin = @"
            <!-- Configure surefire plugin to run tests -->
            <plugin>
                <groupId>org.apache.maven.plugins</groupId>
                <artifactId>maven-surefire-plugin</artifactId>
                <version>3.1.2</version>
                <configuration>
                    <includes>
                        <include>**/*Test.java</include>
                    </includes>
                </configuration>
            </plugin>
"@

$restAssuredDependencies = @"
        <!-- REST Assured for E2E API Testing -->
        <dependency>
            <groupId>io.rest-assured</groupId>
            <artifactId>rest-assured</artifactId>
            <version>5.3.0</version>
            <scope>test</scope>
        </dependency>
        
        <dependency>
            <groupId>io.rest-assured</groupId>
            <artifactId>json-path</artifactId>
            <version>5.3.0</version>
            <scope>test</scope>
        </dependency>
        
        <dependency>
            <groupId>io.rest-assured</groupId>
            <artifactId>xml-path</artifactId>
            <version>5.3.0</version>
            <scope>test</scope>
        </dependency>
"@

foreach ($service in $services) {
    $pomPath = Join-Path -Path $projectRoot -ChildPath "$service\pom.xml"
    
    if (Test-Path $pomPath) {
        Write-Host "Processing $service..."
        $pomContent = Get-Content -Path $pomPath -Raw
        $modified = $false
        
        # Add REST Assured dependencies if not present
        if ($pomContent -notmatch 'io.rest-assured') {
            Write-Host "  Adding REST Assured dependencies to $service"
            $pomContent = $pomContent -replace '([ \t]*)</dependencies>', "$restAssuredDependencies`n`$1</dependencies>"
            $modified = $true
        }
        
        # Add build-helper-maven-plugin if not present
        if ($pomContent -notmatch 'build-helper-maven-plugin') {
            Write-Host "  Adding build-helper-maven-plugin to $service"
            $pluginInsertPoint = '<build>\s*<plugins>'
            if ($pomContent -match $pluginInsertPoint) {
                $pomContent = $pomContent -replace $pluginInsertPoint, "<build>`n        <plugins>`n$buildHelperPlugin"
                $modified = $true
            }
        }
        
        # Add surefire plugin configuration if not properly configured
        if ($pomContent -notmatch '<includes>.*\*\*\/\*Test\.java') {
            Write-Host "  Adding surefire plugin configuration to $service"
            if ($pomContent -match '<plugin>.*?<artifactId>maven-surefire-plugin</artifactId>.*?</plugin>') {
                $pomContent = $pomContent -replace '(<plugin>.*?<artifactId>maven-surefire-plugin</artifactId>.*?)(</plugin>)', "`$1<configuration>`n                    <includes>`n                        <include>**/*Test.java</include>`n                    </includes>`n                </configuration>`n            `$2"
            } else {
                $pluginInsertPoint = $pomContent -match '<build>\s*<plugins>' ? '<build>\s*<plugins>' : '<plugins>'
                $pomContent = $pomContent -replace $pluginInsertPoint, "`$0`n$surefirePlugin"
            }
            $modified = $true
        }
        
        if ($modified) {
            Set-Content -Path $pomPath -Value $pomContent
            Write-Host "  Updated $service pom.xml successfully"
        } else {
            Write-Host "  No changes needed for $service"
        }
    } else {
        Write-Host "Warning: Could not find pom.xml for $service at $pomPath"
    }
}

Write-Host ""
Write-Host "All services have been updated. You can now run tests with:"
Write-Host "mvn clean test"
Write-Host ""
Write-Host "To prepare for GitHub deployment, make sure to:"
Write-Host "1. Create a new GitHub repository if one doesn't exist"
Write-Host "2. Add the GitHub remote: git remote add origin https://github.com/yourusername/your-repo.git"
Write-Host "3. Commit and push your changes: git add . && git commit -m 'Add comprehensive test structure' && git push -u origin master"
