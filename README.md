# Bellabeat Wellness Marketing Analysis

Behavioral segmentation of Fitbit smart-device users to inform marketing strategy for Bellabeat — a women's wellness tech company. Completed as the capstone for the Google Data Analytics Professional Certificate.

**Live interactive dashboard:** [Tableau Public](https://public.tableau.com/views/BellabeatUserSegmentation11/Dashboard1?:language=en-US&:sid=&:redirect=auth&:display_count=n&:origin=viz_share_link)

---

## TL;DR

- Analyzed 33 Fitbit users over 31 days (410 user-days after cleaning) to identify behavioral patterns relevant to Bellabeat's subscription product.
- Performed k-means user segmentation (k=3, validated via elbow analysis) on standardized behavioral features. Three archetypes emerged:
  - **Active Achievers** (24%) — high steps, high vigorous activity, but undersleeping (~6 hrs/night)
  - **Steady Movers** (30%) — balanced activity, healthy sleep
  - **Sedentary Sliders** (45%) — the largest segment; under 5,000 daily steps and over 20 hours sedentary
- Recommended three differentiated marketing tracks per segment, including a sedentary-break feature targeting Sliders (who exceed the WHO 8-hour sedentary threshold by 2.5x).
- Caught 3 duplicate sleep records missed by the widely-cited Kaggle reference notebook.

---

## Tools

- **R** — tidyverse, dplyr, ggplot2, lubridate, cluster (k-means)
- **Tableau Public** — interactive dashboard with linked filters
- **Methods** — k-means clustering, descriptive statistics, data cleaning, exploratory data analysis

---

## Files

| File | Purpose |
|------|---------|
| `bellabeat_capstone_clean.R` | Top-to-bottom reproduction — load, clean, join, summarize, visualize |
| `bellabeat_segmentation.R` | k-means clustering, segment profiling, CSV export for Tableau |
| `bellabeat_tableau_data.csv` | Segment-tagged daily activity dataset (input for the Tableau dashboard) |
| `bellabeat_segment_profile.csv` | Per-segment behavioral averages |

---

## Reproduce

1. Download the [Fitbit Fitness Tracker dataset](https://www.kaggle.com/datasets/arashnic/fitbit) (Mobius, CC0).
2. In RStudio, open `bellabeat_capstone_clean.R`. Update the `setwd()` path on line 21 to point to your local copy of the Fitabase data folder.
3. Run the script top to bottom. The full pipeline executes in seconds.
4. Open `bellabeat_segmentation.R` and run it to produce the segmentation and the Tableau-ready CSV.
5. Open the CSV in Tableau Public (or use the published dashboard linked above).

---

## Limitations

- Sample size of 33 is below the 384 needed for population-level confidence intervals.
- 31-day window misses seasonality.
- No demographic data — can't segment by age or life stage despite Bellabeat being women-focused.
- Sleep data covers only 24 of 33 users (73%); missing values were imputed with the median.
- Data is from 2016 and may not reflect current wearable usage patterns.

---

## Author

**Jonathan Beltran** — pivoting into data analytics from a sales/communication background.

- LinkedIn: [linkedin.com/in/jonathan-beltran-aa2106159](https://www.linkedin.com/in/jonathan-beltran-aa2106159)
- Tableau Public: [public.tableau.com/app/profile/jonathan.beltran8674](https://public.tableau.com/app/profile/jonathan.beltran8674)
