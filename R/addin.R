#' Create Github gists in RStusio
#'
#' This addin enables you to create Github gists in RStusio.
#'
#' The addin currently only supports creating single file gists.
#' More Functionalities of \code{\link{gistr}} package might be added in future
#' releases.
#'
#' @import shiny miniUI
gistrAddin <- function() {
  src_ctx <- NULL
  try(src_ctx <- rstudioapi::getSourceEditorContext(), silent = TRUE)
  if (is.null(src_ctx)) {
    src_filename  <- "None"
  } else if (src_ctx$path == "") {
    src_filename  <- "Untitled"
  } else {
    src_filename  <- basename(src_ctx$path)
  }
  file_type_choices <- c(paste0("current file: ", src_filename), "other")

  ui <- miniPage(
    gadgetTitleBar(
      "Create Github gist",
      right = miniTitleBarButton("done", "Create gist", primary = TRUE)
    ),
    miniContentPanel(
      textInput("gist_desc", "Gist description:", placeholder = "Gist description"),
      radioButtons("file_type", "Gist file:",
                   choices = file_type_choices),
      fileInput("gist_file", label = NULL, accept = "text/plain"),
      radioButtons("gist_type", "Gist type:",
                   choices = c("secret", "public"), selected = "secret"),
      radioButtons("browse", "View in the browser after created:",
                   choices = c("Yes", "No"))
    )
  )

  server <- function(input, output, session) {
    observeEvent(input$done, {
      # select files to commit and gist options
      if(input$file_type == file_type_choices[[1]] && src_filename  != "None") {
        code <- paste0(src_ctx$contents, collapse="\n")
        filename <- src_filename
      } else if(!is.null(input$gist_file)) {
        code <- paste0(readLines(input$gist_file$datapath, warn=FALSE), collapse="\n")
        filename <- input$gist_file$name
      } else {
        code <- NULL
        filename <- NULL
      }
      public <- ifelse(input$gist_type == "public", TRUE, FALSE)
      browse <- input$browse == "Yes"

      # commit gist
      g <- NULL
      if(!is.null(filename)) {
        message(paste0("Creating a gist: ", filename))
        try({
          g <- gistr::gist_create(code = code, filename = filename,
                                  description = input$gist_desc,
                                  public = public, browse = browse)
          message("Done.")
          message(paste0("Gist URL: ", g$html_url))
        })
      } else {
        message("No files selected!")
      }
      stopApp(invisible(g))
    })
  }

  runGadget(ui, server,
            viewer = dialogViewer("Create Github gist", width = 400, height = 600))
}
