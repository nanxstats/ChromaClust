# ChromaClust

Image color topic modeling using
[fastTopics](https://github.com/stephenslab/fastTopics).

## renv

This project uses [renv](https://rstudio.github.io/renv/) to ensure reproducibility. The dependency information is store in `renv.lock`.

Run `renv::restore()` to restore the exact version of dependencies
from `renv.lock`. This will create a project-specific library under
`renv/` and create an `.Rprofile` to use that library when the project
is opened.

## Data

todo

## Image viewer by color topics

A minimal Shiny app is built for easy review of images under
the same color topic or mixture of topics.
To use the app, open the project and run through `R/5-exemplar.R`.

![Shiny app for viewing images by color topics.](images/exemplar.png)
