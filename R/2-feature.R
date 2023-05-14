# Resize images to an acceptable size (width = 256) and
# convert to HSV color histograms

library("doParallel")
registerDoParallel(cores = parallelly::availableCores())

# Create a 10 x 10 x 10 HSV color grid ----
interval_h <- seq(from = -0.0001, to = 360.0001, length.out = 11)
interval_s <- seq(from = -0.0001, to = 1.0001, length.out = 11)
interval_v <- seq(from = -0.0001, to = 1.0001, length.out = 11)

# Generate all color histogram combinations ----
df <- expand.grid(r = 1:10, g = 1:10, b = 1:10)

# Build a dictionary to search ----
dict <- apply(df, 1L, paste, collapse = "&")

# Generate HSV color histogram vector for a given image ----
color_hist <- function(path, size_x = 256, size_y = 256 * 1.5) {
  img_raw <- imager::load.image(path)

  if (length(imager::channels(img_raw)) != 3) {
    img_raw <- imager::flatten.alpha(img_raw, bg = "white")
  }

  img_small <- imager::resize(img_raw, size_x = size_x, size_y = size_y)
  img_small_hsv <- imager::RGBtoHSV(img_small)

  mat_h <- as.matrix(imager::channel(img_small_hsv, 1))
  mat_s <- as.matrix(imager::channel(img_small_hsv, 2))
  mat_v <- as.matrix(imager::channel(img_small_hsv, 3))

  # Extract color histogram from data
  mat_interval_hsv <- rbind(
    findInterval(mat_h, interval_h),
    findInterval(mat_s, interval_s),
    findInterval(mat_v, interval_v)
  )
  img_col <- apply(mat_interval_hsv, 2L, paste, collapse = "&")

  hist_idx <- rep(NA, length(img_col))
  for (j in seq_along(img_col)) hist_idx[j] <- which(img_col[j] == dict)
  hist_tab <- table(hist_idx)

  color_hist <- rep(0L, length(dict))
  color_hist[as.integer(names(hist_tab))] <- hist_tab

  color_hist
}

# Run on all images ----
withr::with_dir(
  "data/movie-poster-5k/",
  {
    fn <- list.files()

    img_color_hist_list <- vector("list", length(fn))
    img_color_hist_list <- foreach(
      i = seq_along(fn)
    ) %dopar% {
      color_hist(fn[i])
    }

    img_color_hist <- do.call(rbind, img_color_hist_list)
  }
)

# Save for later ----
saveRDS(img_color_hist, file = "output/img-color-hist.rds", compress = "xz")
save(dict, interval_h, interval_s, interval_v, file = "output/color-mapping.rda")
