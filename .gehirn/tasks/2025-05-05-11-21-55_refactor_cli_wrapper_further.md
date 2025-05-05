# Task: Further Refactor cli_setup_wrapper.sh

**Objective:** Improve modularity, readability, and maintainability of the `cli_setup_wrapper.sh` script by extracting more logic into dedicated helper scripts.

**Date:** 2025-05-05 11:21:55

**Status:** Pending

## Checklist

-   [x] **DEBUG: Investigate `cli_setup_wrapper.sh` hang after user input:**
    -   [x] Add debug echo statements to `scripts/docker_helpers.sh` (specifically `build_and_launch_docker` and `validate_docker_compose`) to pinpoint the hang.
    -   [x] Analyze the output after re-running the script.
    -   [x] Identify the root cause (e.g., Docker command hang, script logic error, external script issue). -> **Identified: Incorrect subshell output capture using `cat` in `select_from_options` and `prompt_yn` in `scripts/utils.sh`.**
    -   [x] Propose and apply a fix. -> **Applied: Replaced `cat` with direct command substitution `$(...)`.**
-   [ ] **Create `scripts/utils.sh`:**
    -   [ ] Move `debug` function from `cli_setup_wrapper.sh`.
    -   [ ] Move `print_section` function from `cli_setup_wrapper.sh`.
    -   [ ] Move `prompt_yn` function from `cli_setup_wrapper.sh`.
    -   [ ] Move `select_from_options` function from `cli_setup_wrapper.sh`.
    -   [ ] Create `display_access_options` function containing logic from `cli_setup_wrapper.sh` (approx. lines 914-970).
    -   [ ] Add color definitions (BOLD, NORMAL, GREEN, etc.) to `utils.sh` for self-containment.
-   [ ] **Create `scripts/coredns_helpers.sh`:**
    -   [ ] Move `setup_coredns_config` function from `cli_setup_wrapper.sh`.
-   [ ] **Create `scripts/takedown_helpers.sh`:**
    -   [ ] Move `perform_full_takedown` function from `cli_setup_wrapper.sh`.
-   [ ] **Modify `cli_setup_wrapper.sh`:**
    -   [ ] Add `source "$SCRIPT_DIR/scripts/utils.sh"`.
    -   [ ] Add `source "$SCRIPT_DIR/scripts/coredns_helpers.sh"`.
    -   [ ] Add `source "$SCRIPT_DIR/scripts/takedown_helpers.sh"`.
    -   [ ] Remove definitions for `debug`, `print_section`, `prompt_yn`, `select_from_options`.
    -   [ ] Remove definition for `setup_coredns_config`.
    -   [ ] Remove definition for `perform_full_takedown`.
    -   [ ] Replace call to `setup_coredns_config` in Step 3 with call to the function via sourced helper.
    -   [ ] Replace call to `perform_full_takedown` in the 'Full Takedown and Reinstall' case with call to the function via sourced helper.
    -   [ ] Replace the final block displaying access options (approx. lines 914-976) with a call to `display_access_options`.
-   [ ] **(Optional) Refactor `update_existing_installation`:** Break down checks and rebuild steps further if needed.
-   [ ] **(Optional) Refactor Main Flow:** Encapsulate main installation steps logic into dedicated functions (`handle_fresh_install`, etc.).
-   [ ] **Testing:** Verify the refactored script functions correctly for all installation modes (Fresh, Update, Takedown).

**Notes:**
*   Ensure all helper scripts are made executable (`chmod +x`).
*   Verify variable scoping and passing between the main script and helpers (e.g., `SERVER_IP`, `NETWORK_SETUP_DONE`, color variables if not defined in `utils.sh`).
*   The `SCRIPT_DIR=$(dirname "$0")` pattern should be used when sourcing helpers to ensure paths work correctly regardless of where the main script is called from.