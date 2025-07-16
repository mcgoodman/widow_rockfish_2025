# make plot of timeseries of biomass at ages 10+ and 30+

library(dplyr)
library(ggplot2)

# read model output
model <- r4ss::SS_output('models/2025 base model/')

# biomass at age table
x <- model$batage |>
    filter(`Beg/Mid` == "B", Sex == 1, Yr >= 1960, Yr <= 2025) |>
    mutate(sum30plus = rowSums(across(`30`:`40`))) |>
    mutate(sum20plus = rowSums(across(`20`:`40`))) |>
    mutate(sum10plus = rowSums(across(`10`:`40`)))

# last time that biomass at age 30+ was at or above level in 2024
max(x$Yr[x$sum30plus > x$sum30plus[x$Yr == 2024]])
# [1] 1985

# convert to long format for use with ggplot
x_long <- x |>
    select(Yr, sum20plus, sum10plus) |>
    pivot_longer(
        cols = c(sum20plus, sum10plus),
        names_to = "group",
        values_to = "value"
    ) |>
    mutate(
        group = recode(
            group,
            sum30plus = "biomass age 30+",
            sum10plus = "biomass age 10+"
        )
    )

# plot timeseries of biomass at age 10+ and 30+
ggplot(x_long, aes(x = Yr, y = value)) +
    geom_line(size = 1.2) +
    theme_classic() +
    labs(x = "Year", y = "Biomass (mt)", color = "Group") +
    facet_wrap(~group, scales = "free_y", ncol = 1) +
    scale_y_continuous(expand = expansion(mult = c(0, 0.05)), limits = c(0, NA))
ggsave("figures/biomass_at_age_10plus_30plus.png", width = 6.5, height = 6.5)
