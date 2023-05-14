# Show image clusters by the same top-k topics

fit <- readRDS("output/model.rds")

# Use top-3 topics ----
omega <- fit$L
topk <- 3L
n <- nrow(omega)
label <- rep(NA, n)
for (i in seq_len(n)) {
  label[i] <- paste(
    sort(order(omega[i, ], decreasing = TRUE)[seq_len(topk)]),
    collapse = " & "
  ) # Just top-k, no ordering
}

classes <- table(label)
classes
length(classes)

# Interactive image viewer ----
library(shiny)
library(htmltools)

fn <- list.files("data/movie-poster-5k/")

addResourcePath("assets", directoryPath = "data/movie-poster-5k/")
addResourcePath("www", directoryPath = "images/")

ui <- fluidPage(
  theme = bslib::bs_theme(version = 5, bootswatch = "darkly"),
  h1("View images by color topics"),
  p(),
  sidebarLayout(
    sidebarPanel(
      selectInput(
        "class",
        label = "Choose a color topic combination:",
        choices = stringi::stri_sort(names(classes), numeric = TRUE),
        selectize = FALSE
      ),
      p("Hint: see color topic index below"),
      tags$img(src = "www/color-topics.png", width = "100%")
    ),
    mainPanel(
      uiOutput("ui_img")
    )
  )
)

server <- function(input, output) {
  filtered_images <- reactive({
    file.path("assets", fn[label == input$class])
  })

  output$ui_img <- renderUI({
    img_files <- filtered_images()
    table_rows <- tagList()
    row <- tags$tr()
    for (i in seq_along(img_files)) {
      img_file <- img_files[i]
      img_tag <- tags$img(src = img_file, width = "120px")
      td_tag <- tags$td(img_tag)
      row <- tagAppendChild(row, td_tag)
      if (i %% 5 == 0 || i == length(img_files)) {
        table_rows <- tagAppendChild(table_rows, row)
        row <- tags$tr()
      }
    }

    tags$table(table_rows, class = "table table-dark table-hover")
  })
}

shinyApp(ui = ui, server = server)

# Or, plot images to a canvas ----
if (FALSE) {
  idx <- which(label == names(classes)[1])
  idx

  # Select images of interest, assuming on a 2 x 6 grid
  idx <- idx[1:12]

  ragg::agg_png("images/cluster.png", width = 4800, height = 2000, res = 300)
  par(mfrow = c(2, 6), mar = c(0.1, 0.1, 0.1, 0.1))
  for (i in idx) {
    img_raw <- imager::load.image(file.path("data/movie-poster-5k/", fn[i]))
    img_small <- imager::resize(img_raw, size_x = 768, size_y = 768 * 1.5)
    plot(img_small, xaxt = "n", yaxt = "n", frame.plot = FALSE)
  }
  dev.off()
}
