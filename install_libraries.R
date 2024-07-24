packages <- c("dplyr", "tidyr", "optparse", "data.table", "pbapply", "ggplot2", "cowplot")


for (pkg in packages) {
  if (!require(pkg, character.only = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org", dependencies = TRUE)
  }
}
