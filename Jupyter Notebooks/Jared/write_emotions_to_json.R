# Load required libraries
library(jsonlite)

pacman::p_load(pacman, syuzhet, rio, dplyr, pander)

# Initialize an empty list to store the JSON objects
json_list <- list()
json_list_reply <- list()

# get list of subdirectories within data/plots
subdirs <- list.dirs("data/plots", recursive = FALSE)
i = 1
# Example loop for demonstration (replace this with your actual loop)
for (subdir in subdirs) {
  print(basename(subdir))
  print(i)
  # get path to JSON file within subdirectory
  json_file <- paste0('data/comments-data/', basename(subdir), "/", basename(subdir), ".json")
  
  # load data
  json_data <- stream_in(file(json_file))
  # get all comments
  all_data <- json_data[c("text")]
  
  if (length(all_data[[1]]) > 20) {
    parent_data <- json_data[!grepl("\\.", json_data$cid), "text"]
    reply_data <- json_data[grepl("\\.", json_data$cid), "text"]
  
    # separate parent and replies
    #json_lines <- readLines(json_file)
    parent_text_list <- list()
    reply_text_list <- list()
  
    # convert dataframe into a matrix
    x <- as.matrix(all_data[, 1])
    
    ## create emotion lexicon
    nrc_data <- get_nrc_sentiment(x)
    parent_nrc_data <- get_nrc_sentiment(parent_data)

    # get emotions
    emotions <- nrc_data[, 1:8]
    parent_emotions <- parent_nrc_data[, 1:8]

    # create a JSON object for the current iteration
    json_obj <- list(
      id = paste0(basename(subdir)),
      anger = colSums(prop.table(emotions))['anger'],
      anticipation = colSums(prop.table(emotions))['anticipation'],
      disgust = colSums(prop.table(emotions))['disgust'],
      fear = colSums(prop.table(emotions))['fear'],
      joy = colSums(prop.table(emotions))['joy'],
      sadness = colSums(prop.table(emotions))['sadness'],
      surprise = colSums(prop.table(emotions))['surprise'],
      trust = colSums(prop.table(emotions))['trust'],
      
      anger_parent = colSums(prop.table(parent_emotions))['anger'],
      anticipation_parent = colSums(prop.table(parent_emotions))['anticipation'],
      disgust_parent = colSums(prop.table(parent_emotions))['disgust'],
      fear_parent = colSums(prop.table(parent_emotions))['fear'],
      joy_parent = colSums(prop.table(parent_emotions))['joy'],
      sadness_parent = colSums(prop.table(parent_emotions))['sadness'],
      surprise_parent = colSums(prop.table(parent_emotions))['surprise'],
      trust_parent = colSums(prop.table(parent_emotions))['trust']
    )
    
    # reply data
    if (!length(reply_data) == 0) {
      ## create emotion lexicon
      reply_nrc_data <- get_nrc_sentiment(reply_data)
      
      # get emotions
      reply_emotions <- reply_nrc_data[, 1:8]
      
      json_obj_reply <- list(
        id = paste0(basename(subdir)),
        anger_reply = colSums(prop.table(reply_emotions))['anger'],
        anticipation_reply = colSums(prop.table(reply_emotions))['anticipation'],
        disgust_reply = colSums(prop.table(reply_emotions))['disgust'],
        fear_reply = colSums(prop.table(reply_emotions))['fear'],
        joy_reply = colSums(prop.table(reply_emotions))['joy'],
        sadness_reply = colSums(prop.table(reply_emotions))['sadness'],
        surprise_reply = colSums(prop.table(reply_emotions))['surprise'],
        trust_reply = colSums(prop.table(reply_emotions))['trust']
      )
      json_list_reply[[i]] <- json_obj_reply
      
      
    }
    
    # add the JSON object to the list
    json_list[[i]] <- json_obj
    i = i + 1
  }
}

# convert the list to a JSON string
json_string <- jsonlite::toJSON(json_list, pretty = TRUE)
json_string_reply <- jsonlite::toJSON(json_list_reply, pretty = TRUE)

# provide the file path where you want to save the JSON file
file_path <- "data/emotions_all_parent.json"
file_path_reply <- "data/emotions_reply.json"

# save the JSON string to the file
writeLines(json_string, file_path)
writeLines(json_string_reply, file_path_reply)

print(typeof(parent_text_list))



