# depends on code in tables_decision.R
decision1 <- cbind(
    SS_decision_table_stuff(dec_table_reps[[1]]),
    SS_decision_table_stuff(dec_table_reps[[2]]),
    SS_decision_table_stuff(dec_table_reps[[3]])
)
# output looks like
decision1
#      yr catch SpawnBio   dep   yr catch SpawnBio   dep   yr catch SpawnBio   dep
# 1  2025 10669     7281 0.307 2025 10669    10572 0.501 2025 10669    12935 0.632
# 2  2026  9824     6285 0.265 2026  9824     9630 0.456 2026  9824    11972 0.585
# 3  2027  4596     5435 0.229 2027  4596     8799 0.417 2027  4596    11102 0.542
# 4  2028  4810     5393 0.227 2028  4810     8763 0.415 2028  4810    11022 0.538
# 5  2029  5137     5494 0.231 2029  5137     8870 0.420 2029  5137    11084 0.541
# 6  2030  5409     5658 0.238 2030  5409     9054 0.429 2030  5409    11230 0.548
# 7  2031  5545     5807 0.244 2031  5545     9246 0.438 2031  5545    11387 0.556
# 8  2032  5585     5897 0.248 2032  5585     9403 0.445 2032  5585    11519 0.563
# 9  2033  5572     5921 0.249 2033  5572     9521 0.451 2033  5572    11617 0.567
# 10 2034  5535     5895 0.248 2034  5535     9606 0.455 2034  5535    11691 0.571
# 11 2035  5504     5838 0.246 2035  5504     9672 0.458 2035  5504    11751 0.574
# 12 2036  5480     5770 0.243 2036  5480     9726 0.461 2036  5480    11800 0.576

# remove 2nd and 3rd yr and catch columns
decision1 <- decision1[, -c(5, 6, 9, 10)]
# rename columns
colnames(decision1) <- c(
    "Year",
    "Catch_low",
    "SpawnOutput_low",
    "Fraction_unfished_low",
    "SpawnOutput_base",
    "Fraction_unfished_base",
    "SpawnOutput_high",
    "Fraction_unfished_high"
)

decision2 <- cbind(
    SS_decision_table_stuff(dec_table_reps[[1]], smry_bio = TRUE),
    SS_decision_table_stuff(dec_table_reps[[2]], smry_bio = TRUE),
    SS_decision_table_stuff(dec_table_reps[[3]], smry_bio = TRUE)
)

# remove 2nd and 3rd yr and catch columns
decision2 <- decision2[, -c(5, 6, 9, 10)]
# rename columns
colnames(decision2) <- c(
    "Year",
    "Catch_low",
    "Age4+_low",
    "Fraction_unfished_4+_low",
    "Age4+_base",
    "Fraction_unfished_4+_base",
    "Age4+_high",
    "Fraction_unfished_4+_high"
)

decision3 <- cbind(
    SS_decision_table_stuff(dec_table_reps[[1]], OFL = TRUE),
    SS_decision_table_stuff(dec_table_reps[[2]], OFL = TRUE),
    SS_decision_table_stuff(dec_table_reps[[3]], OFL = TRUE)
)

# remove 2nd and 3rd yr and catch columns
decision3 <- decision3[, -c(5, 6, 9, 10)]
# rename columns
colnames(decision3) <- c(
    "Year",
    "Catch_low",
    "OFL_low",
    "Fraction_unfished_low",
    "OFL_base",
    "Fraction_unfished_base",
    "OFL_high",
    "Fraction_unfished_high"
)

# save decision tables
dir.create(here("scratch", "decision_tables"))
write.csv(
    decision1,
    file = here(
        "scratch",
        "decision_tables",
        "decision_table_spawnoutput.csv"
    ),
    row.names = FALSE
)
write.csv(
    decision2,
    file = here(
        "scratch",
        "decision_tables",
        "decision_table_age4plus.csv"
    ),
    row.names = FALSE
)
write.csv(
    decision3,
    file = here("scratch", "decision_tables", "decision_table_OFL.csv"),
    row.names = FALSE
)
