df <- data1$agecomp[data1$agecomp$year >0,]

age_cols <- grep("^m\\d+$", names(df), value = TRUE)

# Reshape from wide to long format
df_long <- reshape(
  df[, c("year", "sex", age_cols)],
  varying = age_cols,
  v.names = "count",
  timevar = "age",
  times = as.numeric(gsub("m", "", age_cols)),
  direction = "long"
)

# Remove NA and zero counts
df_long <- subset(df_long, !is.na(count) & count > 0)

# Aggregate counts by year, sex, and age
agg <- aggregate(count ~ year + sex + age, data = df_long, sum)


# Split by sex for plotting
agg_female <- subset(agg, sex == 2)
agg_male <- subset(agg, sex == 1)

# Set up the plotting window
par(mfrow = c(2, 1), mar = c(4, 4, 2, 1))

# Female plot
with(agg_female, symbols(
  x = year, y = age, circles = sqrt(count), inches = 0.2,
  xlab = "Year", ylab = "Age (yr)", main = "Female"
))

# Male plot
with(agg_male, symbols(
  x = year, y = age, circles = sqrt(count), inches = 0.2,
  xlab = "Year", ylab = "Age (yr)", main = "Male"
))
