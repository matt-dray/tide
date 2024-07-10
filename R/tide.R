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
  
  dat_edited <- utils::edit(dat)
  
  # Factors need to be handled differently to other column types
  is_factor <- sapply(dat, is.factor)
  has_factors <- any(is_factor)
  
  # Convert factors to character to allow '==' comparison
  if (has_factors) {
    
    factor_cols <- names(dat[is_factor])
    
    dat[factor_cols] <- lapply(
      dat[factor_cols],
      function(x) type.convert(x, as.is = TRUE)
    )
    
    dat_edited[factor_cols] <- lapply(
      dat_edited[factor_cols],
      function(x) type.convert(x, as.is = TRUE)
    )
    
  }
  
  if (all(dat == dat_edited) & all(names(dat) == names(dat_edited))) {
    message("No edits were detected.")
    return(dat)
  }
  
  changed <- (dat == dat_edited) & !is.na(dat) & !is.na(dat_edited)
  
  # Generate code snippets to reproduce each cell edit
  
  if (!has_factors) snippets <- build_code_snippets(dat, dat_edited, changed)
  
  if (has_factors) {
    
    # Handle factor/non-factor columns separately 
    
    factor_column_lgl <- dimnames(changed)[[2]] %in% factor_cols
    
    changed_factors <- changed[, which(factor_column_lgl), drop = FALSE]
    snippets_factors <- build_code_snippets(dat, dat_edited, changed_factors)
    
    changed_nonfactors <- changed[, which(!factor_column_lgl), drop = FALSE]
    snippets_nonfactors <- build_code_snippets(dat, dat_edited, changed_nonfactors)
    
    snippets <- c(snippets_nonfactors, snippets_factors)
    
    # Also coerce the edited-data.frame columns back to factors
    dat_edited[factor_cols] <- lapply(dat_edited[factor_cols], as.factor)
    
  } 
  
  if (copy_to_clipboard) {
    code_block <- paste(snippets, collapse = "\n")
    clipr::write_clip(code_block)
    message("Wrote code to clipboard")
  }
  
  dat_edited
  
}

#' Generate Code Snippets for Each Edited Cell of the Input data.frame
#' @param dat_edited A data.frame. The state of the input data.frame after edits.
#' @param changed Logical matrix. `TRUE` for `dat_edited` cells that were
#'     edited.
#' @return A character vector of equal length to the number of edited cells.
#' @noRd
build_code_snippets <- function(dat, dat_edited, changed) {
  
  changed_index <- which(!changed, arr.ind = TRUE)
  changed_nrow <- nrow(changed_index)
  
  snippets <- vector(length = changed_nrow)
  
  for (i in seq(changed_nrow)) {
    
    new_value <- dat_edited[changed_index[i, "row"], changed_index[i, "col"]]
    
    if (!is.numeric(new_value)) {
      new_value <- paste0('"', new_value, '"')
    }
    
    code_string <- paste0(
      as.list(match.call())[["dat"]],  # get the name of the input data.frame
      "[", changed_index[i, "row"], ", ",
      changed_index[i, "col"], "]",
      " <- ", new_value
    )
    
    snippets[i] <- code_string
    
  }
  
  snippets
  
}
