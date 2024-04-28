SE = function(vector, na.rm=F) {
    
  if (na.rm==T) {n = length(!is.na(vector))} else {n = length(vector)}
    
  if (length(unique(na.omit(vector)))==2) {
    
    if (all(sort(unique(na.omit(vector))) == c(0,1))) {
      p = sum(vector, na.rm=na.rm)/n
      se = sqrt(p*(1-p)/n)
    } 
    else {
      se = sd(vector, na.rm=na.rm)/sqrt(sum(!is.na(vector)))
    }
    
  }
  else {
    se = sd(vector, na.rm=na.rm)/sqrt(sum(!is.na(vector)))
  }
  
  if (na.rm==F & any(is.na(vector))) {se = NA}
  
  return(se)
}