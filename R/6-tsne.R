# Use t-SNE to project images to 2D space

library("Rtsne")
library("ggplot2")

fit <- readRDS("output/model.rds")
pal_topics <- readRDS("output/pal-topics.rds")

# Use top-1 topic since this reduces number of clusters ----
omega <- fit$L
topk <- 1L
n <- nrow(omega)
label <- rep(NA, n)
for (i in seq_len(n)) {
  label[i] <- paste(
    sort(order(omega[i, ], decreasing = TRUE)[seq_len(topk)]),
    collapse = "&"
  ) # Just top-k, no ordering
}

classes <- table(label)
classes
length(classes)

# Run t-SNE ----
set.seed(42)
tsne_fit <- Rtsne(omega, dims = 2, verbose = TRUE, check_duplicates = FALSE)

df <- as.data.frame(tsne_fit$Y)
df[, 3] <- factor(as.numeric(factor(label)))
names(df) <- c("X1", "X2", "Color.Topic")

# Save the plot ----
ragg::agg_png("images/t-sne.png", width = 3600, height = 2200, res = 300)
p <- ggplot(df, aes(x = X1, y = X2, color = Color.Topic)) +
  geom_point(alpha = 0.6) +
  scale_color_manual(values = pal_topics) +
  theme_void()
print(p)
dev.off()

# Compress PNG ----
# $ pngquant images/t-sne.png
