
# {tide}

<!-- badges: start -->
[![Project Status: Concept – Minimal or no implementation has been done yet, or the repository is only intended to be a limited example, demo, or proof-of-concept.](https://www.repostatus.org/badges/latest/concept.svg)](https://www.repostatus.org/#concept)
<!-- badges: end -->

Turn the tide on `edit()` by making it reproducible.

Adjust a data.frame manually with a spreadsheet-like data editor and have R code returned that reproduces the changes.

This R package is just for fun with no guarantees. The idea [was prompted by a tweet](https://twitter.com/erdirstats/status/1518529179892994049).

## Demo

Install from GitHub using the {remotes} package:

``` r
remotes::install_github("matt-dray/tide")
```

Let's say we have a demo dataframe:

``` r
df <- data.frame(
  x = c("A", "B", "D"),
  y = c(1, NA, 3)
)

df
#   x  y
# 1 A  1
# 2 B NA
# 3 D  3
```

What if we want to update some of these values? One way is to use `utils::edit()` to open a minimal spreadsheet-like data editor and make the changes manually. This isn't reproducible, however, because no code was stored to show how to get from the old to the new version of the edited object.

The {tide} package's only function, `tide()`, seeks to improve this by generating code that allow you to reproduce the changes.

Pass the data.frame to `tide()` and change the value `"D"` to a `"C"` and the `NA` to a `2` in the data-editor window.

``` r
new_df <- tide::tide(old_df)
# Wrote code to the clipboard

new_df
#   x y
# 1 A 1
# 2 B 2
# 3 C 3
```

The amended data.frame is returned with a message: some R code has been copied to the clipboard that allows you to reproduce the changes. So if you now paste from the clipboard:

``` r
# df[3, 1] <- "C"
# df[2, 2] <- 2
```

Currently, `tide()` only works if you change existing data values (cells). I hope to update it to handle column name changes, along with the creation of new columns and rows.
