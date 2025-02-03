library(jsonlite)

pacman::p_load(pacman, syuzhet, rio, dplyr, pander)

# get list of subdirectories within data/plots
subdirs <- list.dirs("data/plots", recursive = FALSE)

# loop through each file
for (subdir in subdirs) {
  print(basename(subdir))

  # construct output file path
  output_dir <- paste0("data/plots/", basename(subdir))
  output_file <- paste0(output_dir, "/", basename(subdir), "_emotions.pdf")

  if (!file.exists(output_file)) {
    # get path to JSON file within subdirectory
    json_file <- paste0('data/comments-data/', basename(subdir), "/", basename(subdir), ".json")
    
    # load data
    json_data <- stream_in(file(json_file))
    # only get text key
    json_data <- json_data[c("text")]
    
    # convert dataframe into a matrix
    x <- as.matrix(json_data[, 1])
    
    ## create emotion lexicon
    nrc_data <- get_nrc_sentiment(x)
    
    # get emotions
    emotions <- nrc_data[, 1:8]
    
    # the percentage of each emotion is plotted as a bar graph
    pdf(output_file)
    barplot(
      sort(colSums(prop.table(emotions))),
      horiz = TRUE,
      cex.names = 0.7,
      las = 1,
      main = "Emotions in Video", xlab="Percentage"
    )
    dev.off()
  }
}

