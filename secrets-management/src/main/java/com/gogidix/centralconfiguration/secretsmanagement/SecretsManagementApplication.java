package com.gogidix.centralconfiguration.secretsmanagement;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cloud.client.discovery.EnableDiscoveryClient;

/**
 * Secrets Management Application.
 * This service manages secure secrets, keys, and credentials across the ecosystem.
 */
@SpringBootApplication
@EnableDiscoveryClient
public class SecretsManagementApplication {

    public static void main(String[] args) {
        SpringApplication.run(SecretsManagementApplication.class, args);
    }
}