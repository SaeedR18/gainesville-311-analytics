library(readr)
library(dplyr)
library(stringr)
library(tidytext)
library(ggplot2)
library(tidyr)
library(lubridate)
library(wordcloud)
library(RColorBrewer)
library(janitor)
library(tidyverse)
library(ggmap)
library(maps)

# --- Load & Prep Data ---------------------------------------------------------

data <- read_csv("311_Service_Requests_(myGNV)_20251112.csv") %>%
  clean_names()

text_cols <- c(
  "status", "request_type", "description",
  "assigned_to", "reporter_display", "address"
)

clean_text <- function(text_vector) {
  text_vector <- ifelse(is.na(text_vector), "", text_vector)
  text_vector <- str_to_lower(text_vector)
  text_vector <- str_replace_all(text_vector, "[[:punct:]]", " ")
  text_vector <- str_replace_all(text_vector, "\\s+", " ")
  text_vector <- str_trim(text_vector)
  
  sapply(text_vector, function(x) {
    words <- unlist(str_split(x, " "))
    words <- words[!words %in% stop_words$word]
    paste(words, collapse = " ")
  })
}

data <- data %>%
  mutate(across(all_of(text_cols), clean_text)) %>%
  mutate(
    assigned_to = ifelse(
      assigned_to == "public works department (primary)",
      "public works",
      assigned_to
    ),
    assigned_to = ifelse(
      assigned_to %in% c("code enforcement department (primary)", "code enforcement"),
      "code enforcement department",
      assigned_to
    )
  )


# --- Top Category Counts -------------------------------------------------------

data <- data %>%
  mutate(
    service_request_date = lubridate::parse_date_time(
      service_request_date,
      orders = c("mdy HMS", "mdy HM", "mdy", "ymd HMS", "ymd HM", "ymd")
    )
  )



dfDepartment <- data %>% 
  count(assigned_to, name = "req_count") %>% 
  arrange(desc(req_count)) %>% 
  slice(1:6)

dfReq <- data %>% 
  count(request_type, name = "req_count") %>% 
  arrange(desc(req_count)) %>% 
  slice(1:6)

ggplot(dfReq, aes(x = reorder(request_type, req_count), y = req_count)) +
  geom_col(fill = "#ff7f0e") +
  coord_flip() +
  labs(
    x = "Request Type",
    y = "Request Count",
    title = "Top 6 Service Request Types"
  ) +
  theme_classic()

ggplot(dfDepartment, aes(x = reorder(assigned_to, req_count), y = req_count)) +
  geom_col(fill = "#ff7f0e") +
  coord_flip() +
  labs(
    x = "Department",
    y = "Request Count",
    title = "Top 6 Departments by Request Count"
  ) +
  theme_classic()

# --- Sentiment Analysis --------------------------------------------------------

text_df <- data %>%
  mutate(doc_id = row_number()) %>%
  select(doc_id, description, service_request_date) %>%
  filter(description != "")

desc_words <- text_df %>%
  unnest_tokens(word, description) %>%
  anti_join(stop_words, by = "word") %>%
  filter(!str_detect(word, "^[0-9]+$"))

bing_lex <- get_sentiments("bing")

sent_overall <- desc_words %>%
  inner_join(bing_lex, by = "word") %>%
  count(sentiment, name = "n")

ggplot(sent_overall, aes(x = sentiment, y = n, fill = sentiment)) +
  geom_col() +
  labs(
    title = "Sentiment of Gainesville 311 Service Request Descriptions",
    x = "Sentiment",
    y = "Word Count"
  ) +
  theme_minimal() +
  scale_fill_manual(values = c("negative" = "#d62728", "positive" = "#2ca02c"))

sent_by_month <- desc_words %>%
  inner_join(bing_lex, by = "word") %>%
  mutate(month = floor_date(service_request_date, "month")) %>%
  filter(!is.na(month)) %>%                 # drop rows with bad dates
  count(month, sentiment) %>%
  pivot_wider(names_from = sentiment, values_from = n, values_fill = 0) %>%
  mutate(net_sentiment = positive - negative)

if (nrow(sent_by_month) > 0) {
  ggplot(sent_by_month, aes(x = month, y = net_sentiment)) +
    geom_line() +
    geom_hline(yintercept = 0, linetype = "dashed") +
    labs(
      title = "Net Sentiment of 311 Descriptions Over Time",
      x = "Month",
      y = "Net Sentiment"
    ) +
    theme_minimal()
} else {
  message("No valid dates found for sentiment-over-time plot.")
}



# --- Wordcloud -----------------------------------------------------------------

word_counts <- desc_words %>%
  count(word, sort = TRUE)

set.seed(123)
wordcloud(
  words = word_counts$word,
  freq = word_counts$n,
  max.words = 150,
  random.order = FALSE,
  colors = brewer.pal(8, "Dark2")
)

# --- Mapping -------------------------------------------------------------------

register_google(key = Sys.getenv("GOOGLE_API_KEY"))

if (Sys.getenv("GOOGLE_API_KEY") != "") {
  latlon <- geocode("gainesville, fl")
  
  mapzoom <- get_map(
    location = latlon,
    zoom = 12,
    maptype = "terrain"
  )
} else {
  message("No Google API key detected. Map features will be skipped.")
  latlon <- NULL
  mapzoom <- NULL
}

top <- dfReq$request_type

top_reqs_mapdf <- data %>%
  filter(request_type %in% top)

if (!is.null(mapzoom)) {
  ggmap(mapzoom) +
    geom_point(data = top_reqs_mapdf,
               aes(x = longitude, y = latitude, color = request_type),
               alpha = .3) +
    labs(
      title = "Most Frequent Service Requests Map — Gainesville, FL",
      color = "Request Type"
    ) +
    theme_void()
  
  ggmap(mapzoom) +
    stat_density2d(
      data = top_reqs_mapdf,
      aes(x = longitude, y = latitude,
          fill = after_stat(level),
          alpha = after_stat(level)),
      geom = "polygon",
      contour = TRUE
    ) +
    scale_fill_viridis_c(option = "magma") +
    scale_alpha(range = c(0.2, 0.7), guide = FALSE) +
    labs(
      title = "Service Request Density Map — Gainesville, FL",
      fill = "Request Count"
    ) +
    theme_void()
}
