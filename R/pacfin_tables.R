##### PacFIN Tables for 2025 widow
library(tidyverse)
library(flextable)


##Read in the requied tables
table_10_dat <- read.csv(here("report","tables","table_10.csv"))
table_11_dat <- read.csv(here("report","tables","table_11.csv"))
table_13_dat <- read.csv(here("report","tables","table_13.csv"))
table_14_dat <- read.csv(here("report","tables","table_14.csv"))



##Table 10: Number of landings sampled for length data by gear and state for non-whiting fisheries.
table_10_dat|>
  flextable() %>%
  set_header_labels(
    Year = "Year",
    BottomTrawl_CA = "CA", BottomTrawl_OR = "OR", BottomTrawl_WA = "WA",
    MidwaterTrawl_CA = "CA", MidwaterTrawl_OR = "OR", MidwaterTrawl_WA = "WA",
    Net_CA = "CA", Net_WA = "WA",
    HnL_CA = "CA", HnL_OR = "OR", HnL_WA = "WA"
  ) %>%
  add_header_row(
    values = c("Year", rep("Bottom Trawl", 3), rep("Midwater Trawl", 3), 
               rep("Net", 2), rep("Hook-and-line", 3)),
    top = TRUE
  ) %>%
  merge_at(i = 1, j = 2:4, part = "header") %>%
  merge_at(i = 1, j = 5:7, part = "header") %>%
  merge_at(i = 1, j = 8:9, part = "header") %>%
  merge_at(i = 1, j = 10:12, part = "header") %>%
  colformat_num(j = 1, big.mark = "", digits = 0) %>%
  theme_box() %>%
  autofit()


## Table 11 - Number of lengths of Widow Rockfish by gear and state for non-whiting fisheries.
table_11_dat |>
  flextable() %>%
  set_header_labels(
    Year = "Year",
    BottomTrawl_CA = "CA", BottomTrawl_OR = "OR", BottomTrawl_WA = "WA",
    MidwaterTrawl_CA = "CA", MidwaterTrawl_OR = "OR", MidwaterTrawl_WA = "WA",
    Net_CA = "CA", Net_WA = "WA",
    HnL_CA = "CA", HnL_OR = "OR", HnL_WA = "WA"
  ) %>%
  add_header_row(
    values = c("Year", rep("Bottom Trawl", 3), rep("Midwater Trawl", 3), 
               rep("Net", 2), rep("Hook-and-line", 3)),
    top = TRUE
  ) %>%
  merge_at(i = 1, j = 2:4, part = "header") %>%
  merge_at(i = 1, j = 5:7, part = "header") %>%
  merge_at(i = 1, j = 8:9, part = "header") %>%
  merge_at(i = 1, j = 10:12, part = "header") %>%
  colformat_num(j = 1, big.mark = "", digits = 0) %>%
  theme_box() %>%
  autofit()



#### Table 13: Number of landings sampled for ages by gear and state for non-whiting fisheries.
table_13_dat%>%
  flextable() %>%
  set_header_labels(
    Year = "Year",
    BottomTrawl_CA = "CA", BottomTrawl_OR = "OR", BottomTrawl_WA = "WA",
    MidwaterTrawl_CA = "CA", MidwaterTrawl_OR = "OR", MidwaterTrawl_WA = "WA",
    Net_CA = "CA", Net_WA = "WA",
    HnL_CA = "CA", HnL_OR = "OR", HnL_WA = "WA"
  ) %>%
  add_header_row(
    values = c("Year", rep("Bottom Trawl", 3), rep("Midwater Trawl", 3), 
               rep("Net", 2), rep("Hook-and-line", 3)),
    top = TRUE
  ) %>%
  merge_at(i = 1, j = 2:4, part = "header") %>%
  merge_at(i = 1, j = 5:7, part = "header") %>%
  merge_at(i = 1, j = 8:9, part = "header") %>%
  merge_at(i = 1, j = 10:12, part = "header") %>%
  colformat_num(j = 1, big.mark = "", digits = 0) %>%
  theme_box() %>%
  autofit()



## Table 14: Number of ages of Widow Rockfish by gear and state for non-whiting fisheries.
table_14_dat%>%
  flextable() %>%
  set_header_labels(
    Year = "Year",
    BottomTrawl_CA = "CA", BottomTrawl_OR = "OR", BottomTrawl_WA = "WA",
    MidwaterTrawl_CA = "CA", MidwaterTrawl_OR = "OR", MidwaterTrawl_WA = "WA",
    Net_CA = "CA", Net_WA = "WA",
    HnL_CA = "CA", HnL_OR = "OR", HnL_WA = "WA"
  ) %>%
  add_header_row(
    values = c("Year", rep("Bottom Trawl", 3), rep("Midwater Trawl", 3), 
               rep("Net", 2), rep("Hook-and-line", 3)),
    top = TRUE
  ) %>%
  merge_at(i = 1, j = 2:4, part = "header") %>%
  merge_at(i = 1, j = 5:7, part = "header") %>%
  merge_at(i = 1, j = 8:9, part = "header") %>%
  merge_at(i = 1, j = 10:12, part = "header") %>%
  colformat_num(j = 1, big.mark = "", digits = 0) %>%
  theme_box() %>%
  autofit()

