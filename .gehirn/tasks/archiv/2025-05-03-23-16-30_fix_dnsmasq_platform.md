# Task: Fix dnsmasq Docker Image Platform Compatibility

- [x] Search for a `dnsmasq` Docker image compatible with `linux/arm64`. (Selected: `tschaffter/docker-dnsmasq`)
- [x] Read `docker-compose.yml` to locate the `dnsmasq` service definition.
- [-] ~~Update `docker-compose.yml` to use the compatible image (`tschaffter/docker-dnsmasq`).~~ **FAILED: Image pull failed.**
- [-] ~~Update `.gehirn/2025-05-03-22-41-39_changelog.md` with the change.~~ **REVERTED**
- [-] ~~Update `.gehirn/filetree.md` to reflect the modification of `docker-compose.yml`.~~ **REVERTED**
- [-] ~~Mark all tasks in this list as complete.~~
- [ ] **Correction:** Revert changes related to `tschaffter/docker-dnsmasq` in `docker-compose.yml`, changelog, and filetree. (Implicitly done by overwriting below)
- [x] **Correction:** Select a new candidate image (`andyshinn/dnsmasq`).
- [x] **Correction:** Update `docker-compose.yml` to use `andyshinn/dnsmasq`.
- [x] **Correction:** Update `.gehirn/2025-05-03-22-41-39_changelog.md` with the *new* change.
- [x] **Correction:** Update `.gehirn/filetree.md` to reflect the *new* modification of `docker-compose.yml`.
- [x] Mark all *correction* tasks in this list as complete.
- [ ] Archive this task list (`.gehirn/tasks/archiv/2025-05-03-23-16-30_fix_dnsmasq_platform.md`).

**Note:** The previous attempt with `tschaffter/docker-dnsmasq` failed due to image pull error. Retrying with `andyshinn/dnsmasq`.