package com.gogidix.centralconfiguration.deploymentscripts;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cloud.client.discovery.EnableDiscoveryClient;

/**
 * Deployment Scripts Application.
 * This service manages deployment automation and scripts across the ecosystem.
 */
@SpringBootApplication
@EnableDiscoveryClient
public class DeploymentScriptsApplication {

    public static void main(String[] args) {
        SpringApplication.run(DeploymentScriptsApplication.class, args);
    }
}