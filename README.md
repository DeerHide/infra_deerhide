# infra_deerhide
Ansible Configuration for Deerhide Server (RaspberryPi/Nuc)

## Overview

This repository contains Ansible playbooks and roles for managing a multi-host infrastructure setup called "Deerhide". The infrastructure consists of Raspberry Pi and NUC devices running various containerized services for networking, storage, monitoring, and development purposes.

## Infrastructure Components

### Hosts
- **melissa**: Main server running web services and monitoring
- **bunryl**: Storage and development server with MinIO and GPG key management
- **claudia**: Docker-based development environment
- **helene**: Additional Raspberry Pi host

### Services Deployed

#### Core Infrastructure
- **Traefik**: Reverse proxy and load balancer for service routing
- **CoreDNS**: DNS server for internal network resolution
- **Docker**: Container runtime and orchestration
- **HAProxy**: High availability load balancer for Kubernetes API servers

#### Storage & Development
- **MinIO**: S3-compatible object storage service
- **HTTPD**: Web server for serving configuration files and static content

#### Monitoring & Utilities
- **NUT (Network UPS Tools)**: Uninterruptible Power Supply monitoring
- **Auto-updates**: Automated system updates with Slack notifications
- **GPG Key Management**: Automated GPG key generation and deployment

#### User Management
- **Deerhide Users**: Centralized user account management across all hosts
- **Operator Accounts**: Specialized accounts for different team members

## Quick Start

1. Install Ansible and dependencies:
   ```bash
   ./scripts/install_ansible.sh
   ```

2. Configure your environment:
   ```bash
   export ANSIBLE_VAULT_PASSWORD_FILE=/path/to/vault/password
   ```

3. Run playbooks:
   ```bash
   ./scripts/apply_ansible_on_hosts.sh
   ```

## Project Structure

- `ansible/`: Main Ansible configuration
  - `playbook.yml`: Master playbook for all hosts
  - `roles/`: Individual service roles
  - `group_vars/`: Configuration variables
  - `inventories/`: Host inventory definitions
- `scripts/`: Utility scripts for deployment and management
- `ansible-vars.yml`: Additional configuration variables
