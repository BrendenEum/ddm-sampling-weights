#creating the t and s columns
dfPractice <- data.frame(t = paste0("p", 1:15))
dfPractice$s <- sample(1:5, nrow(dfPractice), replace = TRUE)

#creating the e column based off of the s column value
dfPractice$e <- vector("list", length(dfPractice$s))
for (i in 1:nrow(dfPractice)) {
  if (dfPractice$s[i] == 1) {
    dfPractice$e[[i]] <- rnorm(100, mean = -2, sd = 2)
  } else if (dfPractice$s[i] == 2) {
    dfPractice$e[[i]] <- rnorm(100, mean = -1, sd = 2)
  } else if (dfPractice$s[i] == 3) {
    dfPractice$e[[i]] <- rnorm(100, mean = 0, sd = 2)
  } else if (dfPractice$s[i] == 4) {
    dfPractice$e[[i]] <- rnorm(100, mean = 1, sd = 2)
  } else if (dfPractice$s[i] == 5) {
    dfPractice$e[[i]] <- rnorm(100, mean = 2, sd = 2)
  }
}

#lookup table for size 
lookup_table <- data.frame(
  lower_bound = c(-Inf, -2.75, -2.5, -2.25, -2, -1.75, -1.5, -1.25, -1, -0.75, -0.5, -0.25, 0, 0.25, 0.5, 0.75, 1, 1.25, 1.5, 1.75, 2, 2.25, 2.5, 2.75),
  upper_bound = c(-2.75, -2.5, -2.25, -2, -1.75, -1.5, -1.25, -1, -0.75, -0.5, -0.25, 0, 0.25, 0.5, 0.75, 1, 1.25, 1.5, 1.75, 2, 2.25, 2.5, 2.75, Inf),
  stimulus = c(400, 370, 340, 310, 280, 250, 220, 190, 160, 130, 100, 70, 70, 100, 130, 160, 190, 220, 250, 280, 310, 340, 370, 400))

# Create a new column "size" as a list
dfPractice$size <- vector("list", nrow(dfPractice))

# Loop over each row in the data frame
for (i in 1:nrow(dfPractice)) {
  # Extract the "e" values for the current row
  e_values <- dfPractice$e[[i]]
  
  # Find the matching stimuli based on the "e" values
  stimuli <- character(length(e_values))
  for (j in 1:length(e_values)) {
    e_value <- e_values[[j]]
    stim_index <- findInterval(e_value, lookup_table$lower_bound)
    stimuli[j] <- as.character(lookup_table$stim[stim_index])
  }
  
  # Repeat the stimuli to ensure a length of 100 and assign it to the "size" column as a list
  dfPractice$size[i] <- list(rep(stimuli, length.out = 100))
}

#lookup table for color
lookup_table <- data.frame(
  lower_bound = c(-Inf, -2.75, -2.5, -2.25, -2, -1.75, -1.5, -1.25, -1, -0.75, -0.5, -0.25, 0, 0.25, 0.5, 0.75, 1, 1.25, 1.5, 1.75, 2, 2.25, 2.5, 2.75),
  upper_bound = c(-2.75, -2.5, -2.25, -2, -1.75, -1.5, -1.25, -1, -0.75, -0.5, -0.25, 0, 0.25, 0.5, 0.75, 1, 1.25, 1.5, 1.75, 2, 2.25, 2.5, 2.75, Inf),
  stimulus = c("FF0000", "FF0000", "FF0000", "FF0000", "FF0000", "FF0000", "FF0000", "FF0000", "FF0000", "FF0000", "FF0000", "FF0000", "00FF00", 
               "00FF00", "00FF00", "00FF00", "00FF00", "00FF00", "00FF00", "00FF00", "00FF00", "00FF00", "00FF00", "00FF00"))

# Create a new column "color" as a list
dfPractice$color <- vector("list", nrow(dfPractice))

# Loop over each row in the data frame
for (i in 1:nrow(dfPractice)) {
  # Extract the "e" values for the current row
  e_values <- dfPractice$e[[i]]
  
  # Find the matching stimuli based on the "e" values
  stimuli <- character(length(e_values))
  for (j in 1:length(e_values)) {
    e_value <- e_values[[j]]
    stim_index <- findInterval(e_value, lookup_table$lower_bound)
    stimuli[j] <- as.character(lookup_table$stim[stim_index])
  }
  
  # Repeat the stimuli to ensure a length of 100 and assign it to the "color" column as a list
  dfPractice$color[i] <- list(rep(stimuli, length.out = 100))
}