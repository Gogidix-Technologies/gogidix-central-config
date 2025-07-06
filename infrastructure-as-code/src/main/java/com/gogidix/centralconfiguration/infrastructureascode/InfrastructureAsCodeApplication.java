package com.gogidix.centralconfiguration.infrastructureascode;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cloud.client.discovery.EnableDiscoveryClient;

/**
 * Infrastructure as Code Application.
 * This service manages IaC templates and infrastructure provisioning across the ecosystem.
 */
@SpringBootApplication
@EnableDiscoveryClient
public class InfrastructureAsCodeApplication {

    public static void main(String[] args) {
        SpringApplication.run(InfrastructureAsCodeApplication.class, args);
    }
}