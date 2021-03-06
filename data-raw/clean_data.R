# code to reproduce the text data embedded with the package

library(data.table)
library(magrittr)
library(purrr)
library(stringi)

text.files <- list.files(path = "./data-raw/SentenceCorpus/labeled_articles", pattern = "\\.txt", recursive = T, full.names = T)

stop_words_sentences <- readLines("./data-raw/SentenceCorpus/word_lists/stopwords.txt")

dt.list <- list()
for (file in text.files) {
  candidate <- readLines(file, warn = F) %>%
    discard(~ stri_detect_regex(., "^#")) %>%
    map(~ stri_split_regex(., pattern = "\t| ", n = 2) %>% unlist %>% paste(collapse = "|"))
  if (!is_empty(candidate)) {
    dt.list[[file]] <- candidate %>% paste(collapse = "\n") %>% fread(input = ., sep = "|", col.names = c("class.text", "text"), header = F)
  }
}

dt <- rbindlist(dt.list)

dt[, .N, class.text]

test.rows <- sample.int(nrow(dt), 600)
train_sentences <- dt[-test.rows]
test_sentences <- dt[test.rows]

# save files
devtools::use_data(stop_words_sentences, overwrite = TRUE, compress = "gzip")
devtools::use_data(train_sentences, overwrite = TRUE, compress = "gzip")
devtools::use_data(test_sentences, overwrite = TRUE, compress = "gzip")
