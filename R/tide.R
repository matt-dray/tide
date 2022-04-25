#' Edit Manually A Dataframe And Generate Reproducible Code
#'
#' Calls the \code{\link{edit}} function to invoke a spreadsheet-like
#' data-editor window where you can edit a data.frame object by hand. Returns
#' the edited object, but also generates code that can can recreate the amended
#' object from the original.
#'
#' @param df A data.frame to be edited.
#' @param clip Logical, defaults to TRUE. Copy generated code to the clipboard?
#'
#' @details As noted in \code{?dataentry}, 'the data entry editor is only
#'     available on some platforms and GUIs' and 'The details of interface to
#'     the data grid may differ by platform and GUI'.
#'
#' @return A data.frame. Optionally adds a string to the clipboard.
#' @export
#'
#' @examples \dontrun{tide(head(beaver1))}
tide <- function(df, clip = TRUE) {

  if (!"data.frame" %in% class(df)) {
    stop("Input to argument 'df' must be a data.frame object.")
  }

  if (!is.logical(clip)) {
    stop("Input to argument 'clip' must be logical (TRUE or FALSE).")
  }

  df_edited <- utils::edit(df)

  if (all(df == df_edited) & all(names(df) == names(df_edited))) {
    message("No changes were made.")
    return(df_edited)
  }

  changed <- (df == df_edited) & !is.na(df) & !is.na(df_edited)

  changed_index <- which(!changed, arr.ind = TRUE)

  changed_nrow <- nrow(changed_index)

  code_vec <- vector(length = changed_nrow)

  for (i in seq(changed_nrow)) {

    new_value <- df_edited[
      changed_index[i, "row"],
      changed_index[i, "col"]]

    if (!is.numeric(new_value)) {
      new_value <- paste0('"', new_value, '"')
    }

    code_string <- paste0(
      as.list(match.call())[["df"]],
      "[", changed_index[i, "row"], ", ",
      changed_index[i, "col"], "]",
      " <- ", new_value
    )

    code_vec[i] <- code_string

  }

  if (clip) {
    code_block <- paste(code_vec, collapse = "\n")
    clipr::write_clip(code_block)
    message("Wrote code to clipboard")
  }

  df_edited

}
