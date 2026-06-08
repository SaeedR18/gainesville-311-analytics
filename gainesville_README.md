# Gainesville 311 Service Request Analytics

**Tools:** R (tidyverse, tidytext, ggplot2, ggmap, wordcloud) | **Dataset:** 22,900+ records | **Domain:** Public Sector Operations Analytics

---

## Project Overview

This project analyzes Gainesville, Florida's 311 service request dataset (myGNV) to uncover operational trends, departmental workload patterns, public sentiment, and geographic service distribution across the city.

The goal was to transform raw citizen service request data into actionable insights for city planning, resource allocation, and operational efficiency — simulating the kind of data-driven decision support that analytics teams provide to government stakeholders.

**Collaborators:** Saeed Rahman | Cody Copenhaver

---

## Business Questions Answered

- Which service request types generate the highest volume of citizen complaints?
- Which city departments carry the heaviest operational workload?
- What is the overall sentiment of citizen service request descriptions?
- How has public sentiment shifted over time?
- Where are service requests geographically concentrated across Gainesville?

---

## Dataset

**Source:** [myGNV Open Data Portal](https://data.cityofgainesville.org)
**File:** `311_Service_Requests_(myGNV)_20251112.csv`
**Records:** 22,946 service requests
**Time Range:** 2014 – 2025
**Key Fields:**

| Field | Description |
|---|---|
| `Request Type` | Category of service request (Road Repair, Code Enforcement, etc.) |
| `Description` | Free-text citizen description of the issue |
| `Status` | Current status (Archived, Open, Closed) |
| `Assigned To` | Department responsible for resolution |
| `Service Request Date` | Date the request was submitted |
| `Latitude / Longitude` | Geographic coordinates for mapping |
| `Minutes to Close` | Resolution time in minutes |

> **Note:** A 500-row sample is included in `/data/311_data_sample.csv` for demonstration. The full dataset is available at the source link above.

---

## Methodology

### 1. Data Cleaning & Text Normalization
- Loaded raw CSV using `readr` and standardized column names with `janitor`
- Applied custom `clean_text()` function to normalize all text fields:
  - Converted to lowercase
  - Removed punctuation
  - Stripped stop words using `tidytext` stop word lexicon
  - Trimmed whitespace
- Standardized department name variants (e.g., consolidated multiple "Code Enforcement" labels)
- Parsed mixed date formats using `lubridate::parse_date_time()`

### 2. Frequency Analysis
- Counted service requests by `request_type` and `assigned_to`
- Sliced top 6 categories and departments for visualization
- Generated horizontal bar charts using `ggplot2` with `coord_flip()`

### 3. Sentiment Analysis
- Tokenized `description` field using `tidytext::unnest_tokens()`
- Applied Bing sentiment lexicon (`get_sentiments("bing")`) for positive/negative classification
- Calculated overall sentiment word counts
- Computed net monthly sentiment (`positive - negative`) over time using `floor_date()`

### 4. Word Cloud
- Counted term frequency across all cleaned descriptions
- Generated 150-word cloud using `wordcloud` package with `RColorBrewer` color palette

### 5. Geographic Mapping
- Geocoded Gainesville, FL using Google Maps API via `ggmap`
- Plotted top service request types as point overlays on terrain map
- Generated kernel density estimation (KDE) heatmap using `stat_density2d()` to identify service request hotspots

---

## Key Findings

- **Road Repair** and **Code Enforcement** consistently ranked as the highest-volume service request categories
- **Public Works** and **Code Enforcement Department** handled the majority of assigned requests
- Citizen descriptions skewed **negative** in overall sentiment — reflecting the complaint-driven nature of 311 requests
- Net sentiment showed **seasonal patterns** with spikes in negative sentiment during summer months
- Geographic density maps revealed service request **hotspots concentrated near high-density residential corridors** in central and southwest Gainesville

---

## Repository Structure

```
gainesville-311-analytics/
├── README.md                  ← Project overview and methodology
├── analysis.R                 ← Full R analysis script
├── data/
│   └── 311_data_sample.csv    ← 500-row sample dataset
└── outputs/
    └── (charts generated on run)
```

---

## How to Run

### Prerequisites
```r
install.packages(c(
  "readr", "dplyr", "stringr", "tidytext", "ggplot2",
  "tidyr", "lubridate", "wordcloud", "RColorBrewer",
  "janitor", "tidyverse", "ggmap", "maps"
))
```

### Steps
1. Clone the repository
2. Place the full dataset CSV in the project root directory named `311_Service_Requests_(myGNV)_20251112.csv`
3. (Optional) Set your Google Maps API key as an environment variable: `GOOGLE_API_KEY=your_key_here`
4. Run `analysis.R` in RStudio or via `Rscript analysis.R`

> **Note:** Geographic mapping requires a valid Google Maps API key. All other analysis runs without it — the script includes a fallback check that skips mapping if no key is detected.

---

## Skills Demonstrated

- **Data Wrangling:** Multi-format date parsing, text normalization, stop word removal, column standardization
- **Exploratory Analysis:** Frequency analysis, trend identification, categorical aggregation
- **NLP / Text Mining:** Tokenization, sentiment scoring, term frequency analysis, word cloud generation
- **Data Visualization:** Bar charts, time series line plots, word clouds, geographic point maps, KDE density maps
- **Geospatial Analytics:** API-driven geocoding, terrain map overlays, service request hotspot identification
- **R Proficiency:** tidyverse, tidytext, ggplot2, ggmap, lubridate, wordcloud, RColorBrewer, janitor

---

## Authors

**Saeed Rahman** — Data Science & Analytics, University of South Florida
**Cody Copenhaver** — University of South Florida

*Course project — LIS 4934 BSIS Senior Capstone, University of South Florida, Fall 2025*
