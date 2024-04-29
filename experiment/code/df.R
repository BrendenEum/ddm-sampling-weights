#creating the t and s columns
df <- data.frame(t = 1:300)
df$s <- sample(1:5, nrow(df), replace = TRUE)

#creating the e column based off of the s column value
df$e <- vector("list", length(df$s))
for (i in 1:nrow(df)) {
  if (df$s[i] == 1) {
    df$e[[i]] <- rnorm(100, mean = -2, sd = 2)
  } else if (df$s[i] == 2) {
    df$e[[i]] <- rnorm(100, mean = -1, sd = 2)
  } else if (df$s[i] == 3) {
    df$e[[i]] <- rnorm(100, mean = 0, sd = 2)
  } else if (df$s[i] == 4) {
    df$e[[i]] <- rnorm(100, mean = 1, sd = 2)
  } else if (df$s[i] == 5) {
    df$e[[i]] <- rnorm(100, mean = 2, sd = 2)
  }
}

#lookup table for size 
lookup_table <- data.frame(
  lower_bound = c(-Inf, -2.75, -2.5, -2.25, -2, -1.75, -1.5, -1.25, -1, -0.75, -0.5, -0.25, 0, 0.25, 0.5, 0.75, 1, 1.25, 1.5, 1.75, 2, 2.25, 2.5, 2.75),
  upper_bound = c(-2.75, -2.5, -2.25, -2, -1.75, -1.5, -1.25, -1, -0.75, -0.5, -0.25, 0, 0.25, 0.5, 0.75, 1, 1.25, 1.5, 1.75, 2, 2.25, 2.5, 2.75, Inf),
  stimulus = c(400, 370, 340, 310, 280, 250, 220, 190, 160, 130, 100, 70, 70, 100, 130, 160, 190, 220, 250, 280, 310, 340, 370, 400))

# Create a new column "size" as a list
df$size <- vector("list", nrow(df))

# Loop over each row in the data frame
for (i in 1:nrow(df)) {
  # Extract the "e" values for the current row
  e_values <- df$e[[i]]
  
  # Find the matching stimuli based on the "e" values
  stimuli <- character(length(e_values))
  for (j in 1:length(e_values)) {
    e_value <- e_values[[j]]
    stim_index <- findInterval(e_value, lookup_table$lower_bound)
    stimuli[j] <- as.character(lookup_table$stim[stim_index])
  }
  
  # Repeat the stimuli to ensure a length of 100 and assign it to the "size" column as a list
  df$size[i] <- list(rep(stimuli, length.out = 100))
}

#lookup table for color
lookup_table <- data.frame(
  lower_bound = c(-Inf, -2.75, -2.5, -2.25, -2, -1.75, -1.5, -1.25, -1, -0.75, -0.5, -0.25, 0, 0.25, 0.5, 0.75, 1, 1.25, 1.5, 1.75, 2, 2.25, 2.5, 2.75),
  upper_bound = c(-2.75, -2.5, -2.25, -2, -1.75, -1.5, -1.25, -1, -0.75, -0.5, -0.25, 0, 0.25, 0.5, 0.75, 1, 1.25, 1.5, 1.75, 2, 2.25, 2.5, 2.75, Inf),
  stimulus = c("FF0000", "FF0000", "FF0000", "FF0000", "FF0000", "FF0000", "FF0000", "FF0000", "FF0000", "FF0000", "FF0000", "FF0000", "00FF00", 
               "00FF00", "00FF00", "00FF00", "00FF00", "00FF00", "00FF00", "00FF00", "00FF00", "00FF00", "00FF00", "00FF00"))

# Create a new column "color" as a list
df$color <- vector("list", nrow(df))

# Loop over each row in the data frame
for (i in 1:nrow(df)) {
  # Extract the "e" values for the current row
  e_values <- df$e[[i]]
  
  # Find the matching stimuli based on the "e" values
  stimuli <- character(length(e_values))
  for (j in 1:length(e_values)) {
    e_value <- e_values[[j]]
    stim_index <- findInterval(e_value, lookup_table$lower_bound)
    stimuli[j] <- as.character(lookup_table$stim[stim_index])
  }
  
  # Repeat the stimuli to ensure a length of 100 and assign it to the "color" column as a list
  df$color[i] <- list(rep(stimuli, length.out = 100))
}

