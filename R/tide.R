#' Edit Manually A Dataframe And Generate Reproducible Code
#'
#' Calls the \link[utils]{edit} function to invoke a spreadsheet-like
#' data-editor window where you can edit a data.frame object 'by hand'. Returns
#' the edited object and optionally adds code to the clipboard that can recreate
#' the edited object from the original.
#'
#' @param dat A data.frame to be edited. Must be the name of the data.frame
#'     object only.
#' @param copy_to_clipboard Logical, defaults to TRUE. Copy generated code to
#'     the clipboard?
#'
#' @details As noted in \link[utils]{dataentry}, 'the data entry editor is only
#'     available on some platforms and GUIs' and 'The details of interface to
#'     the data grid may differ by platform and GUI'.
#'
#' @return A data.frame. Optionally adds a string to the clipboard.
#' @export
#'
#' @examples \dontrun{beaver1_edited <- tide(beaver1)}
tide <- function(dat, copy_to_clipboard = TRUE) {
  
  if (!"data.frame" %in% class(dat)) {
    stop("Input to argument 'dat' must be a data.frame object.", call. = FALSE)
  }
  
  if (!is.logical(copy_to_clipboard)) {
    stop(
      "Input to argument 'copy_to_clipboard' must be logical (TRUE or FALSE).",
      call. = FALSE
    )
  }
  
  dat_copy <- dat  # keep original and make a copy to edit
  dat_edited <- utils::edit(dat)
  
  # Factors need to be handled differently to other column types
  is_factor <- sapply(dat, is.factor)
  has_factors <- any(is_factor)
  factor_cols <- names(dat[is_factor])  # length 0 if none
  
  # Convert factors to character to allow '==' comparison
  if (has_factors) {
    
    dat_copy[factor_cols] <- lapply(
      dat_copy[factor_cols],
      function(x) utils::type.convert(x, as.is = TRUE)
    )
    
    dat_edited[factor_cols] <- lapply(
      dat_edited[factor_cols],
      function(x) utils::type.convert(x, as.is = TRUE)
    )
    
  }
  
  if (all(dat_copy == dat_edited) & all(names(dat_copy) == names(dat_edited))) {
    message("No edits were detected. Returning original `dat` data.frame.")
    return(dat)
  }
  
  changed <- (dat_copy == dat_edited) & !is.na(dat_copy) & !is.na(dat_edited)
  
  # Generate code snippets to reproduce each cell edit
  snippets <- build_snippets(dat, dat_copy, dat_edited, changed)
  
  if (has_factors) {

    # Coerce the edited-data.frame columns back to factors
    dat_edited[factor_cols] <- lapply(dat_edited[factor_cols], as.factor)

    # Match edit()'s behaviour: original levels plus new ones appended
    
    dat_levels <- lapply(dat[factor_cols], levels)
    dat_edited_levels <- lapply(
      dat_edited[factor_cols],
      function(x) as.character(unlist(x))
    )
    
    new_levels_set <- vector("list", length = length(dat_levels))
    new_levels_set <- stats::setNames(new_levels_set, names(dat_levels))
    
    for (var in names(dat_levels)) {
      new_levels <- setdiff(dat_edited_levels[[var]], dat_levels[[var]])
      new_levels <- if (length(new_levels) == 0) NULL else new_levels
      new_levels_set[[var]] <- new_levels
    }
    
    for (var in names(dat_levels)) {
      updated_levels <- c(as.character(dat[[var]]), new_levels_set[[var]])
      levels(dat_edited[[var]]) <- updated_levels
    }
    
  } 
  
  if (copy_to_clipboard) {
    code_block <- paste(snippets, collapse = "\n")
    clipr::write_clip(code_block)
    message("Wrote reproducible code snippets to the clipboard.")
  }
  
  dat_edited
  
}

#' Generate Code Snippets for Each Edited Cell of the Input data.frame
#' @param dat_edited A data.frame. The state of the input data.frame after edits.
#' @param changed Logical matrix. `TRUE` for `dat_edited` cells that were
#'     edited.
#' @return A character vector of equal length to the number of edited cells.
#' @noRd
build_snippets <- function(dat, dat_copy, dat_edited, changed) {
  
  changed_index <- which(!changed, arr.ind = TRUE)
  changed_n <- nrow(changed_index)
  
  snippets <- c()  # TODO: preallocate (changed_n + 1 for every factor change)
  
  for (i in seq(changed_n)) {
    
    new_value <- dat_edited[changed_index[i, "row"], changed_index[i, "col"]]
    if (is.character(new_value)) new_value <- paste0('"', new_value, '"')
    
    dat_name <- as.list(match.call())[["dat"]]  # name of the input data.frame
    row_index <- changed_index[i, "row"]
    col_index <- changed_index[i, "col"]
    df_index <- paste0(dat_name, "[, ", col_index, "]")
    
    # If the original column is factor, need snippet to add factor level
    # TODO: don't need a snippet if the level already exists
    if (is.factor(dat[, col_index])) {
      
      # Factor levels must be character
      if (is.numeric(new_value)) new_value <- paste0('"', new_value, '"')
      
      code_string <- paste0(
        "levels(", df_index, ") <- ",
        "c(levels(", df_index, "), ", new_value, ")"
      )
      
      snippets <- c(snippets, code_string)
      
    }
    
    code_string <- paste0(
      dat_name, "[", row_index, ", ", col_index, "] <- ", new_value
    )
    
    snippets <- c(snippets, code_string)
    
  }
  
  snippets
  
}
