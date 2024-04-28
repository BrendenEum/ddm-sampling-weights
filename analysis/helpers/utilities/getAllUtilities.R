# Get the list of files in the directory
.file_list <- list.files(file.path("analysis/helpers/utilities"), full.names = TRUE)

# Filter out only R script files
.files <- .file_list[endsWith(.file_list, ".R")]
.R_script_files <- .files[!sapply(.files, grepl, pattern = "getAllUtilities")]

# Run each script file
for (.script_file in .R_script_files) {
  source(.script_file)
}
