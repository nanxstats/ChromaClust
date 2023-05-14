# Pre-process images from all data sources (requires ImageMagick)

withr::with_dir(
  "data/movie-poster-5k/",
  {
    # Remove `.gif` images ----
    fn <- list.files()
    idx_gif <- which(grepl(pattern = ".gif", x = fn))
    file.remove(fn[idx_gif])

    # Remove images smaller than 30kb ----
    # (too small to have rich, comparable color information)
    fn <- list.files()
    fsize <- file.size(fn)
    idx_30kb <- which(fsize <= 30 * 1024)
    file.remove(fn[idx_30kb])

    # Remove duplicated images by checksum ----
    fn <- list.files()
    md5 <- tools::md5sum(fn)
    tmp <- as.vector(md5)
    file.remove(fn[which(duplicated(tmp))])

    # Remove images with width > height ----
    fn <- list.files()
    mat <- matrix(NA, nrow = length(fn), ncol = 2L)

    for (i in seq_along(fn)) {
      cat("\r", i, "of", length(fn), "images processed")
      mat[i, ] <- strsplit(
        strsplit(
          system(
            paste("identify", fn[i]),
            intern = TRUE
          ), " "
        )[[1]][3], "x"
      )[[1]]
    }

    # Standard size: 27" x 41", 41/27 = 1.518 ----
    idx_wide <- which(as.numeric(mat[, 2]) / as.numeric(mat[, 1]) <= 1.33)
    file.remove(fn[idx_wide])
  }
)
