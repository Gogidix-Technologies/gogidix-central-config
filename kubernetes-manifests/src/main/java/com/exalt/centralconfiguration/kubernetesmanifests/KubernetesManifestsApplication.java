package com.exalt.centralconfiguration.kubernetesmanifests;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cloud.client.discovery.EnableDiscoveryClient;

/**
 * Kubernetes Manifests Application.
 * This service manages Kubernetes deployment manifests and orchestration across the ecosystem.
 */
@SpringBootApplication
@EnableDiscoveryClient
public class KubernetesManifestsApplication {

    public static void main(String[] args) {
        SpringApplication.run(KubernetesManifestsApplication.class, args);
    }
}