# after installing new packages, check whether any new packages conflict
# with OpenCPU basics
ocpubasics = rownames(installed.packages(lib = "/usr/lib/R/library"))
userpkgs = rownames(installed.packages(lib = "/usr/local/lib/R/site-library"))
print("Removed duplicate packages")
(dupe_pkgs = userpkgs[ userpkgs %in% ocpubasics])
remove.packages(dupe_pkgs, lib= "/usr/local/lib/R/site-library" )
