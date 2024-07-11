
# {tide}

<!-- badges: start -->
[![Project Status: Concept – Minimal or no implementation has been done yet, or the repository is only intended to be a limited example, demo, or proof-of-concept.](https://www.repostatus.org/badges/latest/concept.svg)](https://www.repostatus.org/#concept)
[![Blog
post](https://img.shields.io/badge/rostrum.blog-post-008900?labelColor=000000&logo=data%3Aimage%2Fgif%3Bbase64%2CR0lGODlhEAAQAPEAAAAAABWCBAAAAAAAACH5BAlkAAIAIf8LTkVUU0NBUEUyLjADAQAAACwAAAAAEAAQAAAC55QkISIiEoQQQgghRBBCiCAIgiAIgiAIQiAIgSAIgiAIQiAIgRAEQiAQBAQCgUAQEAQEgYAgIAgIBAKBQBAQCAKBQEAgCAgEAoFAIAgEBAKBIBAQCAQCgUAgEAgCgUBAICAgICAgIBAgEBAgEBAgEBAgECAgICAgECAQIBAQIBAgECAgICAgICAgECAQECAQICAgICAgICAgEBAgEBAgEBAgICAgICAgECAQIBAQIBAgECAgICAgIBAgECAQECAQIBAgICAgIBAgIBAgEBAgECAgECAgICAgICAgECAgECAgQIAAAQIKAAAh%2BQQJZAACACwAAAAAEAAQAAAC55QkIiESIoQQQgghhAhCBCEIgiAIgiAIQiAIgSAIgiAIQiAIgRAEQiAQBAQCgUAQEAQEgYAgIAgIBAKBQBAQCAKBQEAgCAgEAoFAIAgEBAKBIBAQCAQCgUAgEAgCgUBAICAgICAgIBAgEBAgEBAgEBAgECAgICAgECAQIBAQIBAgECAgICAgICAgECAQECAQICAgICAgICAgEBAgEBAgEBAgICAgICAgECAQIBAQIBAgECAgICAgIBAgECAQECAQIBAgICAgIBAgIBAgEBAgECAgECAgICAgICAgECAgECAgQIAAAQIKAAA7)](https://www.rostrum.blog/posts/2022-04-27-tide/)
<!-- badges: end -->

## About

Turn the tide on R's `edit()` function by making it reproducible.

Adjust a data.frame manually with R's built-in spreadsheet-like data editor and have R code returned that reproduces the changes.

This R package is a limited concept with no guarantees. The idea [was prompted by a tweet](https://twitter.com/erdirstats/status/1518529179892994049). You can [read a blogpost](https://www.rostrum.blog/posts/2022-04-27-tide/) about its development. I don't personally condone manual edits to data. 

## Install

Install from GitHub using the {remotes} package:

``` r
remotes::install_github("matt-dray/tide")
```

## Demo

### Create a demo data.frame

Let's say we have a demo data.frame with lots of different data types in it:

``` r
set.seed(123)
n <- 4; n_seq <- 1:n; let <- LETTERS[n_seq]

(dat <- data.frame(
  var_dbl = runif(n),
  var_int = n_seq,
  var_lgl = sample(c(TRUE, FALSE), 4, TRUE),
  var_char = let,
  var_fct_num = as.factor(n_seq),
  var_fct_char = as.factor(let)
))
#     var_dbl var_int var_lgl var_char var_fct_num var_fct_char
# 1 0.2875775       1    TRUE        A           1            A
# 2 0.7883051       2   FALSE        B           2            B
# 3 0.4089769       3   FALSE        C           3            C
# 4 0.8830174       4   FALSE        D           4            D

str(dat)
# 'data.frame':	4 obs. of  6 variables:
#  $ var_dbl     : num  0.288 0.788 0.409 0.883
#  $ var_int     : int  1 2 3 4
#  $ var_lgl     : logi  TRUE FALSE FALSE FALSE
#  $ var_char    : chr  "A" "B" "C" "D"
#  $ var_fct_num : Factor w/ 4 levels "1","2","3","4": 1 2 3 4
#  $ var_fct_char: Factor w/ 4 levels "A","B","C","D": 1 2 3 4
```

What if we want to update some of these values? One way is to use `utils::edit()` to open a minimal spreadsheet-like data editor and make the changes manually. This isn't reproducible, however, because no code was stored to show how to get from the old to the new version of the edited object.

### Use `tide()` to edit data

The {tide} package's only function, `tide()`, seeks to improve on `edit()` by generating code that reproduces the changes you made.

If we pass the data.frame to `tide()` it will behave in the same way as if we passed it to `edit()`: a spreadsheet-like editor will open in a separate window for editing. Let's say we changed one value per column: double `0.4089769` to `0.1`, integer `1` to `5`, logical `TRUE` to `FALSE`, character `"C"` to `"E"`, factor `"2"` to `"5"` and factor `"A"` to `"E"`.

``` r
new_dat <- tide::tide(dat)  # opens spreadsheet-like editor
# Wrote reproducible code snippets to the clipboard.
# Warning messages:
# 1: In edit.data.frame(dat) : added factor levels in 'var_fct_num'
# 2: In edit.data.frame(dat) : added factor levels in 'var_fct_char'
```

Some messages were returned. First, we're told that reproducible code snippets have been copied onto our clipboard, ready to be pasted. More about this in a moment. We also get a couple of expected warnings: we've added new levels to the factors in a couple of our factor columns.

Let's take a look at the returned `new_dat` data.frame, which contains our edits:

``` r
new_dat
#     var_dbl var_int var_lgl var_char var_fct_num var_fct_char
# 1 0.2875775       5   FALSE        A           1            D
# 2 0.7883051       2   FALSE        B           4            A
# 3 0.1000000       3   FALSE        E           2            B
# 4 0.8830174       4   FALSE        D           3            C

str(new_dat)
# 'data.frame':	4 obs. of  6 variables:
#  $ var_dbl     : num  0.288 0.788 0.1 0.883
#  $ var_int     : num  5 2 3 4
#  $ var_lgl     : logi  FALSE FALSE FALSE FALSE
#  $ var_char    : chr  "A" "B" "E" "D"
#  $ var_fct_num : Factor w/ 5 levels "1","2","3","4",..: 1 4 2 3
#  $ var_fct_char: Factor w/ 5 levels "A","B","C","D",..: 4 1 2 3
```

### Retrieve reproducible code snippets

The code snippets that are now in our clipboard are designed to take the original `dat` data.frame and recreate `new_dat`. Here's what was copied to the clipboard:

``` r
dat[3, 1] <- 0.1
dat[1, 2] <- 5
dat[1, 3] <- FALSE
dat[3, 4] <- "E"
levels(dat[, 5]) <- c(levels(dat[, 5]), "5")
dat[2, 5] <- "5"
levels(dat[, 6]) <- c(levels(dat[, 6]), "E")
dat[1, 6] <- "E"
```

The `dat` data.frame will be updated to match `new_dat` if you excute the snippets:

``` r
all(dat == new_dat)
# [1] TRUE
```

So `tide()` has made `edit()` reoproducible.

### Limitations

This is really just a concept.

* The returned code is pretty basic and quite verbose. It provides a line of code (two for factors) to replace every individual value that was edited.
* The code is only returned in base-R square-bracket notation using column indices rather than the more explicit column names.
* You must pass the data.frame object as-is. For example, you can't wrap it in `head()` like `tide(head(dat))` because this interrupts the function's ability to determine the name of the input-data.frame.
* Currently, `tide()` only works if you change existing data values (cells). It soesn't (yet) handle column name changes, along with the creation of new columns and rows.

If you find any unexpected behaviour, please leave an issue or make a pull request.
