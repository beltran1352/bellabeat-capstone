# =============================================================
# Bellabeat Case Study — Google Data Analytics Capstone
# Author: Jonathan Beltran
# Date:   April 2026
# Source: Fitbit Fitness Tracker Data (Mobius / Kaggle, CC0)
#         33 users, April 12 – May 12, 2016
# =============================================================
# This script reproduces the full Process and Analyze phases of
# the case study. Run top-to-bottom in RStudio with the working
# directory set to the Fitabase Data folder.
# =============================================================


# -------------------------------------------------------------
# 0. Setup
# -------------------------------------------------------------

# Set working directory to the Fitabase data folder
setwd("~/Desktop/Data Analyst /Coursera Capstone/Fitbit Fitness Data(Mobius)/mturkfitbit_export_4.12.16-5.12.16/Fitabase Data 4.12.16-5.12.16")

# Load packages (install once with install.packages() if needed)
library(tidyverse)   # dplyr, ggplot2, readr, tibble, etc.
library(lubridate)   # date parsing helpers: mdy(), mdy_hms(), hour()
library(janitor)     # clean_names(), get_dupes()  -- optional but handy


# -------------------------------------------------------------
# 1. Import the three working tables
# -------------------------------------------------------------

daily_activity <- read_csv("dailyActivity_merged.csv")     # 940 rows x 15 cols
sleep_day      <- read_csv("sleepDay_merged.csv")          # 413 rows x  5 cols
hourly_steps   <- read_csv("hourlySteps_merged.csv")       # 22,099 rows x 3 cols


# -------------------------------------------------------------
# 2. Sniff test (universal 6-question check)
#    Run this for each table. Repeats are fine — fast and cheap.
# -------------------------------------------------------------

sniff <- function(df, date_col) {
  cat("---- ", deparse(substitute(df)), " ----\n", sep = "")
  cat("Rows: ", nrow(df), "\n", sep = "")
  cat("Unique users: ", n_distinct(df$Id), "\n", sep = "")
  cat("Date range: ", as.character(min(df[[date_col]])), " to ",
      as.character(max(df[[date_col]])), "\n", sep = "")
  cat("Duplicate rows: ", sum(duplicated(df)), "\n", sep = "")
  cat("Total NAs: ", sum(is.na(df)), "\n\n", sep = "")
}

sniff(daily_activity, "ActivityDate")   # 940, 33 users, 0 dupes, 0 NAs
sniff(sleep_day,      "SleepDay")       # 413, 24 users, 3 dupes, 0 NAs  <-- catch
sniff(hourly_steps,   "ActivityHour")   # 22,099, 33 users, 0 dupes, 0 NAs


# -------------------------------------------------------------
# 3. Clean
#    a) Drop the 3 sleep duplicates.
#    b) Convert text date columns to real Date type so we can join.
# -------------------------------------------------------------

sleep_day <- sleep_day %>% distinct()                       # 413 -> 410

daily_activity$date <- as.Date(mdy(daily_activity$ActivityDate))
sleep_day$date      <- as.Date(mdy_hms(sleep_day$SleepDay))
hourly_steps$datetime <- mdy_hms(hourly_steps$ActivityHour)
hourly_steps$hour     <- hour(hourly_steps$datetime)


# -------------------------------------------------------------
# 4. Merge sleep + activity on Id + date  (inner join)
# -------------------------------------------------------------

merged_data <- merge(sleep_day, daily_activity, by = c("Id", "date"))
# 410 rows, 20 columns -- one row per user-day with both dimensions
glimpse(merged_data)


# -------------------------------------------------------------
# 5. Descriptive statistics  (these go in the report)
# -------------------------------------------------------------

# Daily activity numbers
daily_activity %>%
  select(TotalSteps, TotalDistance, SedentaryMinutes, Calories) %>%
  summary()

daily_activity %>%
  select(VeryActiveMinutes, FairlyActiveMinutes, LightlyActiveMinutes) %>%
  summary()

# Sleep numbers
sleep_day %>%
  select(TotalSleepRecords, TotalMinutesAsleep, TotalTimeInBed) %>%
  summary()


# -------------------------------------------------------------
# 6. Visualizations
# -------------------------------------------------------------

# 6a. Average steps by hour of day  (surfaces 5-7 PM peak)
avg_steps_by_hour <- hourly_steps %>%
  group_by(hour) %>%
  summarise(avg_steps = mean(StepTotal, na.rm = TRUE), .groups = "drop")

ggplot(avg_steps_by_hour, aes(x = hour, y = avg_steps)) +
  geom_col(fill = "#1F3A5F") +
  scale_x_continuous(breaks = 0:23) +
  labs(
    title    = "Average steps by hour of day",
    subtitle = "Activity peaks 5-7 PM with a secondary peak at noon",
    x = "Hour of day (24h)",
    y = "Average steps"
  ) +
  theme_minimal()


# 6b. Sedentary minutes vs. minutes asleep  (inverse relationship)
ggplot(merged_data, aes(x = SedentaryMinutes, y = TotalMinutesAsleep)) +
  geom_point(alpha = 0.5, color = "#1F3A5F") +
  geom_smooth(method = "loess", se = FALSE, color = "#D97706") +
  labs(
    title    = "More sedentary time, less sleep",
    subtitle = "Users with the highest sedentary minutes tend to sleep less",
    x = "Sedentary minutes per day",
    y = "Total minutes asleep"
  ) +
  theme_minimal()


# 6c. Distribution of total daily steps with 10k benchmark line
ggplot(daily_activity, aes(x = TotalSteps)) +
  geom_histogram(binwidth = 1000, fill = "#1F3A5F", color = "white") +
  geom_vline(xintercept = 10000, linetype = "dashed", color = "#D97706", linewidth = 1) +
  annotate("text", x = 10500, y = 80, label = "CDC goal: 10,000",
           hjust = 0, color = "#D97706") +
  labs(
    title    = "Most users fall short of 10,000 steps — but not by much",
    subtitle = "Median 7,406 steps; the gap is closeable with coaching",
    x = "Total steps per day",
    y = "Number of user-days"
  ) +
  theme_minimal()


# -------------------------------------------------------------
# 7. End. Findings feed directly into the case study writeup.
# -------------------------------------------------------------
