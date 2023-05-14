# Find top differential colors in all topics

library("fastTopics")

load("output/color-mapping.rda")
fit <- readRDS("output/model.rds")
img_color_hist <- readRDS("output/img-color-hist.rds")

# Identify differential colors presented in individual topics ----
set.seed(42)
diff_colors <- de_analysis(
  fit,
  X = img_color_hist,
  pseudocount = 0.1,
  control = list(ns = 1e4, nc = parallelly::availableCores())
)

saveRDS(diff_colors, "output/diff-colors.rds")

diff_colors <- readRDS("output/diff-colors.rds")

# Find top colors in each topic ----
k <- 10
top_colors <- 50
palettes <- matrix(NA, nrow = k, ncol = top_colors)
for (i in seq_len(k)) {
  dat <- data.frame(
    postmean = diff_colors$postmean[, i],
    z = diff_colors$z[, i],
    lfsr = diff_colors$lfsr[, i]
  )
  dat <- subset(dat, lfsr < 0.01)
  dat <- dat[order(dat$postmean, decreasing = TRUE), ]
  palettes[i, ] <- as.integer(rownames(dat)[seq_len(top_colors)])
}

# Get h, s, v values for each color ----
palettes_list <- vector("list", nrow(palettes))
for (i in seq_along(palettes_list)) {
  palettes_list[[i]] <- vector("list", ncol(palettes))
}
for (i in seq_along(palettes_list)) {
  for (j in seq_along(palettes_list[[i]])) {
    h_idx <- as.integer(strsplit(dict[palettes[i, j]], "&")[[1]][1])
    s_idx <- as.integer(strsplit(dict[palettes[i, j]], "&")[[1]][2])
    v_idx <- as.integer(strsplit(dict[palettes[i, j]], "&")[[1]][3])
    palettes_list[[i]][[j]]["H"] <- mean(c(interval_h[h_idx], interval_h[h_idx + 1]))
    palettes_list[[i]][[j]]["S"] <- mean(c(interval_s[s_idx], interval_s[s_idx + 1]))
    palettes_list[[i]][[j]]["V"] <- mean(c(interval_v[v_idx], interval_v[v_idx + 1]))
  }
}

# Plot color topics and save the top-1 colors in each topic as a palette ----
pal_topics <- rep(NA, k)

ragg::agg_png("images/color-topics.png", width = 1200, height = 1000)
par(mfrow = c(k, 1), mar = c(0.3, 1, 0.3, 1))
for (i in seq_along(palettes_list)) {
  mycol <- rep(NA, length(palettes_list[[i]]))
  for (j in seq_along(palettes_list[[i]])) {
    mycol[j] <- hsv(
      palettes_list[[i]][[j]]["H"] / 360,
      palettes_list[[i]][[j]]["S"],
      palettes_list[[i]][[j]]["V"]
    )
  }
  # The third color in each topic seems representative
  pal_topics[i] <- mycol[3L]
  barplot(rep(1, length(palettes_list[[i]])),
    col = mycol,
    space = 0.1, yaxt = "n", border = NA
  )
}
dev.off()

# Save the one representative color for each topic as palette ----
saveRDS(pal_topics, file = "output/pal-topics.rds")

# Crop the image ----
# $ convert -trim images/color-topics.png images/color-topics.png
