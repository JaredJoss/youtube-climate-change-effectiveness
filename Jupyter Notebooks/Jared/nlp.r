library(jsonlite)

pacman::p_load(pacman, syuzhet, rio, dplyr, pander)

# load data
file_names <- list.files(path='data/comments-data')
json_data <- stream_in(file("data/comments-data/5Gk9gIpGvSE/5Gk9gIpGvSE.json"))
# only get text key
json_data <- json_data[c("text")]

head(json_data)

# convert dataframe into a matrix
x <- as.matrix(json_data[, 1])

# create sentiment vectors
syuzhet_vector <- get_sentiment(x, method = "syuzhet")
bing_vector <- get_sentiment(x, method = "bing")
afinn_vector <- get_sentiment(x, method = "afinn")
nrc_vector <- get_sentiment(x, method = "nrc", lang = "english")

# compare sentiments (different scales) 
rbind(
  sign(head(syuzhet_vector)),
  sign(head(bing_vector)),
  sign(head(afinn_vector)),
  sign(head(nrc_vector))
)

# sum of emotional valence in text
sum(syuzhet_vector)
# mean of emotional valence
mean(syuzhet_vector)
# summary of emotional valence
summary(syuzhet_vector)

## create emotion lexicon
nrc_data <- get_nrc_sentiment(x)
head(nrc_data)

# get emotions
emotions <- nrc_data[, 1:8]
head(emotions)

# get positive/negative valences
valence <- nrc_data[, 9:10]
head(valence)

# the percentage of each emotion is plotted as a bar graph
pdf(paste0('test', ".pdf"))
barplot(
  sort(colSums(prop.table(emotions))), 
  horiz = TRUE, 
  cex.names = 0.7, 
  las = 1, 
  main = "Emotions in Video", xlab="Percentage"
)
dev.off()
