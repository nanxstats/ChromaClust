# Fit topic model

library("fastTopics")

img_color_hist <- readRDS("output/img-color-hist.rds")

# Fit topic model ----
# Use K = 10 by assuming each topic has 1 major color
# choose(10, 1) = 10 since we have major 10 colors (H intervals)
set.seed(42)
fit <- fit_topic_model(img_color_hist, k = 10)

# Other possibilities for K tried ----
# - K = 20.
#   choose(10, 1) + choose(5, 2) = 20.
#   Assume 10 topics have 1 major color, 5 topics have 2 major colors.
# - K = 55.
#   choose(10, 1) + choose(10, 2) = 55.
#   Assume 10 topics have 1 major color, 10 topics have 2 major colors.
# - K = 9, 11, 12, 13, 14.

# Structure plot ----
structure_plot(fit, colors = ggsci::pal_d3()(10))

# Save the topic model ----
saveRDS(fit, file = "output/model.rds", compress = "xz")
