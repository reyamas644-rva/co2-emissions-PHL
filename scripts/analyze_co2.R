
# ==========================================================
# INDIVIDUAL ECOLOGY LAB
# COUNTRY-LEVEL CO2 EMISSIONS ANALYSIS
# Country: Philippines (PHL)
# Study Period: 1990-2024
# Data Source: Our World in Data
# ==========================================================

# 1. COUNTRY SETTINGS

country_code <- "PHL"
start_year <- 1990
end_year <- 2024

# 2. CREATE OUTPUT FOLDERS

for (folder in c("data", "figures", "results")) {
  dir.create(folder, showWarnings = FALSE, recursive = TRUE)
}

# 3. DATA SOURCE

source_url <- "https://owid-public.owid.io/data/co2/owid-co2-data.csv"

full_csv <- "data/owid-co2-data.csv"

# Download only if the original file is missing
if (!file.exists(full_csv)) {
  options(timeout = 300)
  download.file(source_url, full_csv, mode = "wb")
}

# 4. READ DATASET

all_data <- read.csv(full_csv, stringsAsFactors = FALSE)

needed <- c("country", "iso_code", "year", "co2",
            "co2_per_capita")

if (!all(needed %in% names(all_data))) {
  stop("Required columns are missing.")
}

# 5. EXTRACT PHILIPPINES DATA

country_data <- all_data[
  all_data$iso_code == country_code &
    all_data$year >= start_year &
    all_data$year <= end_year,
  needed,
  drop = FALSE
]

if (nrow(country_data) == 0) {
  stop("No Philippines data found.")
}

country_data <- country_data[
  order(country_data$year), ]

# Save country-only CSV
country_csv <- "data/PHL_co2.csv"

write.csv(country_data, country_csv,
          row.names = FALSE, na = "")

# Read the saved country-specific dataset
d <- read.csv(country_csv)

# 6. CHECK DATA

valid_co2 <- d[!is.na(d$co2), ]

if (nrow(valid_co2) == 0) {
  stop("No usable CO2 data.")
}

country_name <- d$country[1]

# 7. CREATE PLOTTING FUNCTION

save_plot <- function(x, y, filename,
                      title_text, y_label) {
  
  good <- !is.na(x) & is.finite(y)
  
  if (sum(good) < 2) {
    message("Not enough data for plot: ", filename)
    return(invisible(FALSE))
  }
  
  png(filename, width = 1440, height = 840, res = 160)
  
  plot(x[good], y[good],
       type = "o",
       pch = 16,
       col = "#21618C",
       lwd = 2,
       xlab = "Year",
       ylab = y_label,
       main = title_text)
  
  grid()
  dev.off()
}

# 8. GRAPH 1: ANNUAL CO2 EMISSIONS

save_plot(
  d$year,
  d$co2,
  "figures/PHL_annual_co2.png",
  "Philippines - Annual CO2 Emissions",
  "Million tonnes CO2/year"
)

# 9. GRAPH 2: CO2 EMISSIONS PER CAPITA

save_plot(
  d$year,
  d$co2_per_capita,
  "figures/PHL_per_capita.png",
  "Philippines - CO2 Emissions Per Capita",
  "Tonnes CO2/person/year"
)

# 10. GRAPH 3: ANNUAL PERCENTAGE CHANGE

d$change_pct <- NA_real_

if (nrow(d) >= 2) {
  
  for (i in 2:nrow(d)) {
    
    adjacent <- d$year[i] == d$year[i - 1] + 1
    
    usable <- !is.na(d$co2[i]) &&
      !is.na(d$co2[i - 1]) &&
      d$co2[i - 1] > 0
    
    if (adjacent && usable) {
      d$change_pct[i] <-
        100 * (d$co2[i] / d$co2[i - 1] - 1)
    }
  }
}

save_plot(
  d$year,
  d$change_pct,
  "figures/PHL_annual_change.png",
  "Philippines - Annual CO2 Change",
  "Change from previous year (%)"
)

# 11. SUMMARY STATISTICS

first <- valid_co2[1, ]
last <- valid_co2[nrow(valid_co2), ]

peak <- valid_co2[which.max(valid_co2$co2), ]

endpoint_change <- if (first$co2 > 0) {
  100 * (last$co2 / first$co2 - 1)
} else {
  NA_real_
}

pc <- d[!is.na(d$co2_per_capita), ]

last_pc <- if (nrow(pc) > 0) {
  tail(pc$co2_per_capita, 1)
} else {
  NA_real_
}

summary_table <- data.frame(
  country = country_name,
  iso_code = country_code,
  first_year = first$year,
  last_year = last$year,
  first_co2_mt = first$co2,
  last_co2_mt = last$co2,
  endpoint_change_percent = endpoint_change,
  peak_year = peak$year,
  peak_co2_mt = peak$co2,
  latest_co2_per_capita_t = last_pc
)

write.csv(
  summary_table,
  "results/PHL_summary.csv",
  row.names = FALSE
)

# 12. SAVE YEARLY CHANGES

write.csv(
  d[, c("year", "co2", "co2_per_capita", "change_pct")],
  "results/PHL_yearly_changes.csv",
  row.names = FALSE
)

# 13. SAVE R SESSION INFORMATION

writeLines(
  c(
    paste("Source:", source_url),
    paste("Processed:", Sys.time()),
    capture.output(sessionInfo())
  ),
  "results/session_info.txt"
)

# 14. DISPLAY FINAL RESULTS

print(summary_table)

cat("\nANALYSIS COMPLETED SUCCESSFULLY!\n")
cat("Country: Philippines\n")
cat("Study Period: 1990-2024\n")
cat("Check your figures and results folders.\n")
source("scripts/analyze_co2.R")