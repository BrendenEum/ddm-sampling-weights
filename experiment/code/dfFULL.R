library(tibble)

# Create an empty data frame dfFULL with the desired column names
dfFULL <- tibble(randomise_blocks = integer(),
               randomise_trials = integer(),
               display = character(),
               t = numeric(),
               s = numeric(),
               e = list(character()),
               size = list(character()),
               color = list(character()))

# Create two rows
row1 <- data.frame(randomise_blocks = "", randomise_trials = "", display = "instr", t = "", s = "", e = "", size = "", color = "")
row2 <- data.frame(randomise_blocks = "", randomise_trials = "", display = "practiceStart", t = "", s = "", e = "", size = "", color = "")

# Append the rows to dfFULL
dfFULL <- rbind(dfFULL, row1)
dfFULL <- rbind(dfFULL, row2)

# Iterate through the rows of dfPractice
for (i in 1:15) {
  # Create the trial row
  practice_row <- data.frame(randomise_blocks = 0,
                          randomise_trials = 0,
                          display = "trial",
                          t = dfPractice$t[i],
                          s = dfPractice$s[i],
                          e = I(list(paste(dfPractice$e[i], collapse = ","))), 
                          size = I(list(paste(dfPractice$size[i], collapse = ","))),
                          color = I(list(paste(dfPractice$color[i], collapse = ","))),
                          stringsAsFactors = FALSE)

  
  # Append the trial row to dfFULL
  dfFULL <- rbind(dfFULL, practice_row)
}

# Create two rows
row3 <- data.frame(randomise_blocks = "", randomise_trials = "", display = "practiceEnd", t = "", s = "", e = "", size = "", color = "")
row4 <- data.frame(randomise_blocks = "", randomise_trials = "", display = "blockStart", t = "", s = "", e = "", size = "", color = "")

# Append the rows to dfFULL
dfFULL <- rbind(dfFULL, row3)
dfFULL <- rbind(dfFULL, row4)

# Iterate through the rows of df for Block 1
for (i in 1:50) {
  # Create the trial row
  trial_row <- data.frame(randomise_blocks = 1,
                          randomise_trials = 1,
                          display = "trial",
                          t = df$t[i],
                          s = df$s[i],
                          e = I(list(paste(df$e[i], collapse = ","))), 
                          size = I(list(paste(df$size[i], collapse = ","))),
                          color = I(list(paste(df$color[i], collapse = ","))),
                          stringsAsFactors = FALSE)
  
  # Append the trial row to dfFULL
  dfFULL <- rbind(dfFULL, trial_row)
}

# Create 3 rows
row5 <- data.frame(randomise_blocks = "", randomise_trials = "", display = "blockEnd1", t = "", s = "", e = "", size = "", color = "")
row6 <- data.frame(randomise_blocks = "", randomise_trials = "", display = "bonus", t = "", s = "", e = "", size = "", color = "")
row7 <- data.frame(randomise_blocks = "", randomise_trials = "", display = "blockStart2", t = "", s = "", e = "", size = "", color = "")

# Append the rows to dfFULL
dfFULL <- rbind(dfFULL, row5)
dfFULL <- rbind(dfFULL, row6)
dfFULL <- rbind(dfFULL, row7)

# Iterate through the rows of df for Block 2
for (i in 51:100) {
  # Create the trial row
  trial_row <- data.frame(randomise_blocks = 1,
                          randomise_trials = 1,
                          display = "trial",
                          t = df$t[i],
                          s = df$s[i],
                          e = I(list(paste(df$e[i], collapse = ","))), 
                          size = I(list(paste(df$size[i], collapse = ","))),
                          color = I(list(paste(df$color[i], collapse = ","))),
                          stringsAsFactors = FALSE)
  
  # Append the trial row to dfFULL
  dfFULL <- rbind(dfFULL, trial_row)
}

# Create 3 rows
row8 <- data.frame(randomise_blocks = "", randomise_trials = "", display = "blockEnd2", t = "", s = "", e = "", size = "", color = "")
row9 <- data.frame(randomise_blocks = "", randomise_trials = "", display = "bonus", t = "", s = "", e = "", size = "", color = "")
row10 <- data.frame(randomise_blocks = "", randomise_trials = "", display = "blockStart3", t = "", s = "", e = "", size = "", color = "")

# Append the rows to dfFULL
dfFULL <- rbind(dfFULL, row8)
dfFULL <- rbind(dfFULL, row9)
dfFULL <- rbind(dfFULL, row10)

# Iterate through the rows of df for Block 3
for (i in 101:150) {
  # Create the trial row
  trial_row <- data.frame(randomise_blocks = 1,
                          randomise_trials = 1,
                          display = "trial",
                          t = df$t[i],
                          s = df$s[i],
                          e = I(list(paste(df$e[i], collapse = ","))), 
                          size = I(list(paste(df$size[i], collapse = ","))),
                          color = I(list(paste(df$color[i], collapse = ","))),
                          stringsAsFactors = FALSE)
  
  # Append the trial row to dfFULL
  dfFULL <- rbind(dfFULL, trial_row)
}

# Create 3 rows
row11 <- data.frame(randomise_blocks = "", randomise_trials = "", display = "blockEnd3", t = "", s = "", e = "", size = "", color = "")
row12 <- data.frame(randomise_blocks = "", randomise_trials = "", display = "bonus", t = "", s = "", e = "", size = "", color = "")
row13 <- data.frame(randomise_blocks = "", randomise_trials = "", display = "blockStart4", t = "", s = "", e = "", size = "", color = "")


# Append the rows to dfFULL
dfFULL <- rbind(dfFULL, row11)
dfFULL <- rbind(dfFULL, row12)
dfFULL <- rbind(dfFULL, row13)

# Iterate through the rows of df for Block 4
for (i in 151:200) {
  # Create the trial row
  trial_row <- data.frame(randomise_blocks = 1,
                          randomise_trials = 1,
                          display = "trial",
                          t = df$t[i],
                          s = df$s[i],
                          e = I(list(paste(df$e[i], collapse = ","))), 
                          size = I(list(paste(df$size[i], collapse = ","))),
                          color = I(list(paste(df$color[i], collapse = ","))),
                          stringsAsFactors = FALSE)
  
  # Append the trial row to dfFULL
  dfFULL <- rbind(dfFULL, trial_row)
}

# Create 3 rows
row14 <- data.frame(randomise_blocks = "", randomise_trials = "", display = "blockEnd4", t = "", s = "", e = "", size = "", color = "")
row15 <- data.frame(randomise_blocks = "", randomise_trials = "", display = "bonus", t = "", s = "", e = "", size = "", color = "")
row16 <- data.frame(randomise_blocks = "", randomise_trials = "", display = "blockStart5", t = "", s = "", e = "", size = "", color = "")

# Append the rows to dfFULL
dfFULL <- rbind(dfFULL, row14)
dfFULL <- rbind(dfFULL, row15)
dfFULL <- rbind(dfFULL, row16)

# Iterate through the rows of df for Block 5
for (i in 201:250) {
  # Create the trial row
  trial_row <- data.frame(randomise_blocks = 1,
                          randomise_trials = 1,
                          display = "trial",
                          t = df$t[i],
                          s = df$s[i],
                          e = I(list(paste(df$e[i], collapse = ","))), 
                          size = I(list(paste(df$size[i], collapse = ","))),
                          color = I(list(paste(df$color[i], collapse = ","))),
                          stringsAsFactors = FALSE)
  
  # Append the trial row to dfFULL
  dfFULL <- rbind(dfFULL, trial_row)
}

# Create the 5th and 6th rows
row17 <- data.frame(randomise_blocks = "", randomise_trials = "", display = "blockEnd5", t = "", s = "", e = "", size = "", color = "")
row18 <- data.frame(randomise_blocks = "", randomise_trials = "", display = "bonus", t = "", s = "", e = "", size = "", color = "")
row19 <- data.frame(randomise_blocks = "", randomise_trials = "", display = "blockStart6", t = "", s = "", e = "", size = "", color = "")

# Append the rows to dfFULL
dfFULL <- rbind(dfFULL, row17)
dfFULL <- rbind(dfFULL, row18)
dfFULL <- rbind(dfFULL, row19)

# Iterate through the remaining rows of df for Block 6
for (i in 251:300) {
  # Create the trial row
  trial_row <- data.frame(randomise_blocks = 2,
                          randomise_trials = 2,
                          display = "trial",
                          t = df$t[i],
                          s = df$s[i],
                          e = I(list(paste(df$e[i], collapse = ","))), 
                          size = I(list(paste(df$size[i], collapse = ","))),
                          color = I(list(paste(df$color[i], collapse = ","))),
                          stringsAsFactors = FALSE)
  
  
  # Append the trial row to dfFULL
  dfFULL <- rbind(dfFULL, trial_row)
}

# Create the end row
end_row <- data.frame(randomise_blocks = "", randomise_trials = "", display = "end", t = "", s = "", e = "", size = "", color = "")
bonus <- data.frame(randomise_blocks = "", randomise_trials = "", display = "bonus", t = "", s = "", e = "", size = "", color = "")

# Append the end row to dfFULL
dfFULL <- rbind(dfFULL, end_row)
dfFULL <- rbind(dfFULL, bonus)

# Convert list columns to character
dfFULL$e <- sapply(dfFULL$e, paste, collapse = ",")
dfFULL$size <- sapply(dfFULL$size, paste, collapse = ",")
dfFULL$color <- sapply(dfFULL$color, paste, collapse = ",")

# Save the modified data frame as a CSV file
write.csv(dfFULL, file = "dfFULL.csv", row.names = FALSE)
