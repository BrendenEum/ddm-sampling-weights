write.text = function(text, file) {
  writeLines(
    toString(text), 
    file,
    sep=""
  )
}