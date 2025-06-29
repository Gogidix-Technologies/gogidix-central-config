package com.exalt.centralconfiguration.dbmigrations;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cloud.client.discovery.EnableDiscoveryClient;

/**
 * Database Migrations Application.
 * This service manages database schema migrations across the ecosystem.
 */
@SpringBootApplication
@EnableDiscoveryClient
public class DatabaseMigrationsApplication {

    public static void main(String[] args) {
        SpringApplication.run(DatabaseMigrationsApplication.class, args);
    }
}