package com.gogidix.centralconfiguration.regionaldeployment;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cloud.client.discovery.EnableDiscoveryClient;

/**
 * Regional Deployment Application.
 * This service manages multi-region deployment strategies across the ecosystem.
 */
@SpringBootApplication
@EnableDiscoveryClient
public class RegionalDeploymentApplication {

    public static void main(String[] args) {
        SpringApplication.run(RegionalDeploymentApplication.class, args);
    }
}