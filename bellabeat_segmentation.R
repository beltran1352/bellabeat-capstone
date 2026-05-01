# =============================================================
# Bellabeat — User Segmentation (k-means on behavioral features)
# Author: Jonathan Beltran
# =============================================================
# Run AFTER bellabeat_capstone_clean.R (this assumes daily_activity
# and sleep_day are already loaded and merged_data exists).
#
# What this script does:
#   1. Builds a per-user feature table (one row per user, behavioral
#      averages across the 31-day window).
#   2. Standardizes the features so big-magnitude variables (steps)
#      don't dominate small-magnitude ones (very-active minutes).
#   3. Picks k=3 clusters (justified below) and runs k-means.
#   4. Profiles each cluster — what does each segment look like?
#   5. Exports a segment-tagged CSV ready to feed into Tableau.
# =============================================================


# -------------------------------------------------------------
# 0. Setup — make sure these are loaded
# -------------------------------------------------------------
library(tidyverse)
library(lubridate)
# install.packages("cluster") if you haven't already
library(cluster)


# -------------------------------------------------------------
# 1. Build per-user feature table
#    One row per user. Columns are the behaviors we want to
#    cluster on: average steps, sedentary minutes, very-active
#    minutes, and minutes asleep (for users who logged sleep).
# -------------------------------------------------------------

user_features <- daily_activity %>%
  group_by(Id) %>%
  summarise(
    avg_steps           = mean(TotalSteps,           na.rm = TRUE),
    avg_sedentary       = mean(SedentaryMinutes,     na.rm = TRUE),
    avg_very_active     = mean(VeryActiveMinutes,    na.rm = TRUE),
    avg_lightly_active  = mean(LightlyActiveMinutes, na.rm = TRUE),
    days_logged         = n(),
    .groups = "drop"
  )

# Add sleep average (left join — users without sleep records get NA)
sleep_summary <- sleep_day %>%
  group_by(Id) %>%
  summarise(avg_minutes_asleep = mean(TotalMinutesAsleep, na.rm = TRUE),
            .groups = "drop")

user_features <- user_features %>%
  left_join(sleep_summary, by = "Id")

# For clustering, we need complete cases. Replace missing sleep with
# the median so we don't drop users (24 of 33 logged sleep).
user_features$avg_minutes_asleep[is.na(user_features$avg_minutes_asleep)] <-
  median(user_features$avg_minutes_asleep, na.rm = TRUE)

print(user_features)


# -------------------------------------------------------------
# 2. Standardize features (z-score)
#    Steps range 0–15000, very-active minutes range 0–60.
#    Without scaling, k-means would cluster almost entirely on steps.
# -------------------------------------------------------------

cluster_features <- user_features %>%
  select(avg_steps, avg_sedentary, avg_very_active, avg_minutes_asleep)

scaled_features <- scale(cluster_features)


# -------------------------------------------------------------
# 3. Pick k. We use k=3 because (a) with only 33 users, more than
#    3 clusters splinters into groups too small to write recs for,
#    and (b) 3 maps cleanly to the marketing question: low / mid /
#    high engagement archetypes. The elbow plot below confirms 3 is
#    a reasonable choice.
# -------------------------------------------------------------

set.seed(42)  # reproducibility — same clusters every run

# Optional: elbow plot to sanity-check k
wss <- sapply(1:8, function(k) kmeans(scaled_features, centers = k, nstart = 25)$tot.withinss)
plot(1:8, wss, type = "b",
     xlab = "Number of clusters (k)",
     ylab = "Total within-cluster sum of squares",
     main = "Elbow plot — looking for the bend")

km <- kmeans(scaled_features, centers = 3, nstart = 25)


# -------------------------------------------------------------
# 4. Profile the clusters — what does each segment actually look like?
# -------------------------------------------------------------

user_features$segment_id <- km$cluster

segment_profile <- user_features %>%
  group_by(segment_id) %>%
  summarise(
    n_users             = n(),
    avg_steps           = round(mean(avg_steps)),
    avg_sedentary_min   = round(mean(avg_sedentary)),
    avg_very_active_min = round(mean(avg_very_active), 1),
    avg_minutes_asleep  = round(mean(avg_minutes_asleep)),
    .groups = "drop"
  ) %>%
  arrange(desc(avg_steps))

print(segment_profile)

# Assign human-readable labels based on the profile.
# After running once, look at segment_profile and rename if needed.
# Typical pattern with this dataset:
#   highest steps + lowest sedentary  -> "Active Achievers"
#   mid steps + moderate sedentary    -> "Steady Movers"
#   lowest steps + highest sedentary  -> "Sedentary Sliders"

segment_profile <- segment_profile %>%
  mutate(segment_label = case_when(
    row_number() == 1 ~ "Active Achievers",
    row_number() == 2 ~ "Steady Movers",
    row_number() == 3 ~ "Sedentary Sliders"
  ))

print(segment_profile)

# Push labels back onto the user table
user_features <- user_features %>%
  left_join(segment_profile %>% select(segment_id, segment_label),
            by = "segment_id")


# -------------------------------------------------------------
# 5. Export a segment-tagged daily-activity CSV for Tableau.
#    One row per user-day, with the user's segment label attached
#    so we can filter the dashboard by segment.
# -------------------------------------------------------------

tableau_data <- daily_activity %>%
  left_join(user_features %>% select(Id, segment_label), by = "Id") %>%
  left_join(sleep_day %>% select(Id, date, TotalMinutesAsleep),
            by = c("Id", "ActivityDate" = "date"))

# Add the date-as-Date column for Tableau
tableau_data$date <- as.Date(lubridate::mdy(tableau_data$ActivityDate))

# Save to Downloads so Tableau can find it
write_csv(tableau_data, "~/Downloads/bellabeat_tableau_data.csv")

# Also save the segment profile for the writeup
write_csv(segment_profile, "~/Downloads/bellabeat_segment_profile.csv")

cat("\n====  DONE  ====\n")
cat("Wrote: ~/Downloads/bellabeat_tableau_data.csv\n")
cat("Wrote: ~/Downloads/bellabeat_segment_profile.csv\n")
cat("\nPaste the segment_profile output back to Claude so we can\n")
cat("write the segment-specific recommendations.\n")
