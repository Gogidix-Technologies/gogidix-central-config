package com.exalt.centralconfiguration.disasterrecovery;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cloud.client.discovery.EnableDiscoveryClient;

/**
 * Disaster Recovery Application.
 * This service manages backup, recovery, and business continuity across the ecosystem.
 */
@SpringBootApplication
@EnableDiscoveryClient
public class DisasterRecoveryApplication {

    public static void main(String[] args) {
        SpringApplication.run(DisasterRecoveryApplication.class, args);
    }
}