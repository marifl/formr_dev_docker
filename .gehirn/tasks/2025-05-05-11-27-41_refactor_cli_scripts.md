# Task List: Refactor CLI Setup Scripts

- [x] **1. Remove/Fix `scripts/apply_patches.sh`:** Eliminate the redundant wrapper script.
- [x] **2. Merge `_lib.sh` into `utils.sh`:**
    - [x] Combine all general utility functions (logging, prompts, colors, editor invocation, DB helpers, file utils, container checks, password generation) into `scripts/utils.sh`.
    - [x] Standardize logging/output functions (e.g., a single `log` function supporting levels).
    - [x] Create a reusable `invoke_editor` function.
- [x] **3. Centralize IP Handling:**
    - [x] Create a `get_local_ip` function in the merged `utils.sh`.
    - [x] Refactor `https_helpers.sh` and `utils.sh` (specifically `display_access_options`) to use this function.
    - [x] Minimize reliance on global IP variables by passing IPs as parameters where possible.
- [x] **4. Clean Up Unused/Redundant Code:**
    - [x] Verify the usage of `safe_exec`. Remove if unused.
    - [x] Decide whether to use `find_replace_in_file` consistently or remove it if direct `sed` calls are preferred.
- [x] **5. Relocate `restart_containers`:** Move the function from `https_helpers.sh` to `docker_helpers.sh`.
- [x] **6. Standardize Error Handling:** Review functions to ensure they consistently return 0 for success and non-zero for failure.
- [x] **7. Reduce Global Variable Reliance:** Refactor functions to accept flags like `DEBUG` or necessary context as parameters instead of relying on globally scoped variables.