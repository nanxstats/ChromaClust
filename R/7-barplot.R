# Stacked bar chart on polar axis as structure plot

source("R/polar-barplot.R")

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

# Construct plot input
df <- data.frame(
  family = factor(rep(paste("Cluster", label), each = 10), levels = paste("Cluster", 1:10)),
  item = factor(rep(as.character(seq_len(nrow(omega))), each = 10)),
  Color.Topic = factor(rep(paste("Topic", 1:10), nrow(omega)), levels = paste("Topic", 1:10)),
  value = as.vector(t(omega))
)

# Save the plot ----
ragg::agg_png("images/structure.png", width = 2000, height = 2000, res = 300)
p <- polar_barplot(
  df,
  familyLabels = FALSE,
  alphaStart = -0.52,
  circleProportion = 0.99,
  innerRadius = 0.2,
  guides = c(10, 20, 40, 80),
  spaceItem = 0.01,
  spaceFamily = 0.1,
  palette = pal_topics
)
print(p)
dev.off()

# Crop the image ----
# $ convert -trim images/structure.png images/structure.png
# $ pngquant images/structure.png
