library("ggplot2")
library("plyr")

#' Polar bar chart
#'
#' @note
#' From <https://github.com/chrislad/phenotypicForest>,
#' see <http://htmlpreview.github.io/?https://github.com/chrislad/phenotypicForest/blob/master/inst/doc/PhenotypicForests.html>.
#'
#' @examples
#' # Simulation data example
#' set.seed(42)
#' nFamily <- 10
#' nItemPerFamily <- sample(1:80, nFamily, replace = TRUE)
#' nValues <- 10
#'
#' randomWord <- function(n, nLetters = 8) {
#'   replicate(n, paste(sample(letters, nLetters, replace = TRUE), sep = "", collapse = ""))
#' }
#'
#' sim <- data.frame(
#'   family = rep(randomWord(nFamily), times = nValues * nItemPerFamily),
#'   item   = rep(randomWord(sum(nItemPerFamily), 3), each = nValues),
#'   score  = rep(paste0("V", 1:nValues), times = sum(nItemPerFamily)),
#'   value  = round(500 * runif(sum(nItemPerFamily * nValues)), 2)
#' )
#'
#' head(sim)
#' names(sim) <- c("family", "item", "Color.Topic", "value")
#' levels(sim$Color.Topic) <- paste("Topic", 1:10)
#'
#' polar_barplot(sim,
#'   familyLabels = TRUE,
#'   alphaStart = -0.3, circleProportion = 0.99,
#'   innerRadius = 0.3, guides = c(10, 20, 40, 80)
#' )
polar_barplot <- function(
    df, family = NULL, columnNames = NULL, binSize = 1,
    spaceItem = 0.2, spaceFamily = 1.2, innerRadius = 0.3, outerRadius = 1,
    guides = c(10, 20, 40, 80), alphaStart = -0.3, circleProportion = 0.8,
    direction = "inwards", familyLabels = FALSE, normalised = TRUE,
    palette) {
  if (!is.null(columnNames)) {
    namesColumn <- names(columnNames)
    names(namesColumn) <- columnNames
    df <- rename(df, namesColumn)
  }

  applyLookup <- function(groups, keys, unassigned = "unassigned") {
    lookup <- rep(names(groups), sapply(groups, length, USE.NAMES = FALSE))
    names(lookup) <- unlist(groups, use.names = FALSE)
    p <- lookup[as.character(keys)]
    p[is.na(p)] <- unassigned
    p
  }

  if (!is.null(family)) df$family <- applyLookup(family, df$item)
  df <- arrange(df, family, item, Color.Topic)
  if (normalised) {
    df <- ddply(df, .(family, item), transform, value = cumsum(value / (sum(value))))
  } else {
    maxFamily <- max(plyr::ddply(df, .(family, item), summarise, total = sum(value))$total)
    df <- ddply(df, .(family, item), transform, value = cumsum(value))
    df$value <- df$value / maxFamily
  }

  df <- ddply(df, .(family, item), transform, previous = c(0, head(value, length(value) - 1)))

  df2 <- ddply(df, .(family, item), summarise, indexItem = 1)
  df2$indexItem <- cumsum(df2$indexItem)
  df3 <- ddply(df, .(family), summarise, indexFamily = 1)
  df3$indexFamily <- cumsum(df3$indexFamily)
  df <- merge(df, df2, by = c("family", "item"))
  df <- merge(df, df3, by = "family")
  df <- arrange(df, family, item, Color.Topic)

  affine <- switch(direction,
    inwards = function(y) (outerRadius - innerRadius) * y + innerRadius,
    outwards = function(y) (outerRadius - innerRadius) * (1 - y) + innerRadius,
    stop(paste("Unknown direction"))
  )

  df <- within(df, {
    xmin <- (indexItem - 1) * binSize + (indexItem - 1) *
      spaceItem + (indexFamily - 1) * (spaceFamily - spaceItem)
    xmax <- xmin + binSize
    ymin <- affine(1 - previous)
    ymax <- affine(1 - value)
  })

  if (normalised) {
    guidesDF <- data.frame(
      xmin = rep(df$xmin, length(guides)),
      y = rep(1 - guides / 100, 1, each = nrow(df))
    )
  } else {
    guidesDF <- data.frame(
      xmin = rep(df$xmin, length(guides)),
      y = rep(1 - guides / maxFamily, 1, each = nrow(df))
    )
  }

  guidesDF <- within(guidesDF, {
    xend <- xmin + binSize
    y <- affine(y)
  })

  totalLength <- tail(df$xmin + binSize + spaceFamily, 1) / circleProportion - 0

  p <- ggplot(df) +
    geom_rect(aes(
      xmin = xmin, xmax = xmax,
      ymin = ymin, ymax = ymax, fill = Color.Topic
    ))

  # # Remove sample labels

  # readableAngle <- function(x) {
  #   angle <- x * (-360/totalLength) - alphaStart * 180/pi + 90
  #   angle + ifelse(sign(cos(angle * pi/180)) + sign(sin(angle * pi/180)) == -2, 180, 0)
  # }

  # readableJustification <- function(x) {
  #   angle <- x * (-360/totalLength) - alphaStart * 180/pi + 90
  #   ifelse(sign(cos(angle * pi/180)) + sign(sin(angle * pi/180)) == -2, 1, 0)
  # }

  # dfItemLabels <- ddply(df, .(family, item), summarize, xmin = xmin[1])
  # dfItemLabels <- within(dfItemLabels, {
  #   x <- xmin + binSize/2
  #   angle <- readableAngle(xmin + binSize/2)
  #   hjust <- readableJustification(xmin + binSize/2)
  # })
  #
  # p <- p + geom_text(aes(x = x, label = item, angle = angle,
  #                        hjust = hjust), y = 1.02, size = 3, vjust = 0.5, data = dfItemLabels)

  p <- p + geom_segment(aes(x = xmin, xend = xend, y = y, yend = y),
    colour = "white", data = guidesDF
  )

  if (normalised) {
    guideLabels <- data.frame(
      x = 0, y = affine(1 - guides / 100),
      label = as.character(guides / 100)
    )
  } else {
    guideLabels <- data.frame(
      x = 0, y = affine(1 - guides / maxFamily),
      label = paste(guides, " ", sep = "")
    )
  }

  p <- p + geom_text(aes(x = x, y = y, label = label),
    data = guideLabels,
    angle = -alphaStart * 180 / pi, hjust = 1, size = 1.5
  )
  if (familyLabels) {
    familyLabelsDF <- aggregate(xmin ~ family,
      data = df,
      FUN = function(s) mean(s + binSize)
    )
    familyLabelsDF <- within(familyLabelsDF, {
      x <- xmin
      angle <- xmin * (-360 / totalLength) - alphaStart * 180 / pi
    })
    p <- p + geom_text(aes(x = x, label = family, angle = angle),
      data = familyLabelsDF, y = 1.1
    )
  }

  p <- p + theme(
    panel.background = element_blank(), axis.title.x = element_blank(),
    axis.title.y = element_blank(), panel.grid.major = element_blank(),
    panel.grid.minor = element_blank(), axis.text.x = element_blank(),
    axis.text.y = element_blank(), axis.ticks = element_blank()
  )

  p <- p + xlim(0, tail(df$xmin + binSize + spaceFamily, 1) / circleProportion)
  p <- p + ylim(0, outerRadius + 0.2)
  p <- p + coord_polar(start = alphaStart)
  p <- p + scale_fill_manual(values = palette)
  p
}
