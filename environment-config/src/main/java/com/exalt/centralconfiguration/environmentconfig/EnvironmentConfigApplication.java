package com.exalt.centralconfiguration.environmentconfig;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cloud.client.discovery.EnableDiscoveryClient;

/**
 * Environment Configuration Application.
 * This service manages environment-specific configurations across the ecosystem.
 */
@SpringBootApplication
@EnableDiscoveryClient
public class EnvironmentConfigApplication {

    public static void main(String[] args) {
        SpringApplication.run(EnvironmentConfigApplication.class, args);
    }
}