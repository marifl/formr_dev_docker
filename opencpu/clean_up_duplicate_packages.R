# Function to remove duplicate package installations
clean_up_duplicate_packages <- function() {
  # Get all library paths
  lib_paths <- .libPaths()
  
  # Get all installed packages
  installed_packages <- installed.packages()
  
  # Get unique package names
  unique_packages <- unique(installed_packages[, "Package"])
  
  # For each unique package
  for (pkg in unique_packages) {
    # Find all instances of the package
    instances <- which(installed_packages[, "Package"] == pkg)
    
    # If there are multiple instances
    if (length(instances) > 1) {
      # Get their versions
      versions <- installed_packages[instances, "Version"]
      
      # Find the latest version
      latest_version <- max(versions)
      
      # Remove all but the latest version
      for (i in instances) {
        # If it's not the latest version, remove it
        if (installed_packages[i, "Version"] != latest_version) {
          pkg_lib_path <- installed_packages[i, "LibPath"]
          pkg_path <- file.path(pkg_lib_path, pkg)
          cat("Removing duplicate package:", pkg, "version", installed_packages[i, "Version"], "from", pkg_lib_path, "\n")
          try(remove.packages(pkg, lib = pkg_lib_path))
        }
      }
    }
  }
  
  cat("Done cleaning up duplicate packages.\n")
}

# Execute the clean-up function
clean_up_duplicate_packages()
