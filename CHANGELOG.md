# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.1] - 2026-05-26

### Fixed

- `svc_netboot_xyz`: switch the container to `network_mode: host` so the
  TFTP data channel (which uses a fresh ephemeral source port per RFC
  1350) is reachable from PXE clients. Docker's bridge NAT cannot track
  TFTP without the `nf_conntrack_tftp` helper, which produced
  `PXE-E18: Server response timeout` on bare-metal boot.

### Changed

- `svc_netboot_xyz`: move the assets nginx off port `80` to `8081`
  (`netboot_xyz_assets_port`) to avoid colliding with Traefik now that
  the container shares the host network namespace.
- `svc_netboot_xyz`: the assets Traefik service label now uses
  `netboot_xyz_assets_port` instead of the hardcoded `80`, so changing
  the port no longer requires touching the role.
- `svc_traefik`: add `host.docker.internal -> host-gateway` to the
  Traefik container's `/etc/hosts`. Traefik v3's Docker provider relies
  on this lookup to route to containers that use `network_mode: host`.

## [0.1.0] - 2026-05-26

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
- Initial `CHANGELOG.md` following the Keep a Changelog format to track
  notable project changes from this release onward.

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

[Unreleased]: https://github.com/DeerHide/infra_deerhide/compare/v0.1.1...HEAD
[0.1.1]: https://github.com/DeerHide/infra_deerhide/compare/v0.1.0...v0.1.1
[0.1.0]: https://github.com/DeerHide/infra_deerhide/releases/tag/v0.1.0
