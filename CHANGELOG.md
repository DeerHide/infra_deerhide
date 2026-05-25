# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- `svc_netboot_xyz` role to deploy netboot.xyz in Docker, exposing the
  TFTP UDP endpoint and publishing the web UI and assets host behind
  Traefik with Cloudflare TLS and HTTP to HTTPS redirection.
- `marlene-playbook.yml` and matching `host_vars/marlene.yml`, wired into
  the entrypoint `playbook.yml`, to provision the marlene host with
  updates, users, GPG, Docker, Traefik, Alloy, Portainer agent and the
  new netboot.xyz service.
- `group_vars/all/netboot_xyz.yml` with default container, port and
  storage settings for the netboot.xyz service.

### Changed

- Bump Traefik Docker image from `3.0` to `3.7` to pick up upstream fixes
  on a supported v3 line.
- Switch the Ansible stdout callback to the built-in `default` callback
  with `callback_result_format=yaml`, replacing the `community.general.yaml`
  callback that was removed in `community.general` 12.

### Fixed

- `operator_gpg` role now uses the actual fact name `operator_gpg_key_exists`
  in its `when` condition (instead of the undefined `gpg_key_exists`) and
  uses the negated boolean form, removing the `literal-compare` lint
  suppression.

[Unreleased]: https://github.com/DeerHide/infra_deerhide/compare/HEAD...HEAD
