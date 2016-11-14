cp <- read.table("C:/Users/Lena/Documents/Uni/Master Marburg/1. Semester/Datenanalyse/4.Stunde/AI001_gebiet_flaeche.txt",
                 skip = 6, header = TRUE, sep = ";", dec = ",",
                 fill = TRUE, encoding="ANSI")

head(cp)

str(cp)

#New column names
names(cp) <- c("Year", "ID", "Place", "Anteil_Siedlungs-_&_Verkehrsfläche", "Anteil_Erholungsfläche", 
               "Anteil_Landwirtschaftsfläche", "Anteil_Waldfläche")

# Numbers as numbers, not characters/factors
for(c in colnames(cp)[4:7]){
  cp[, c][cp[, c] == "." |
            cp[, c] == "-" |
            cp[, c] == "," | 
            cp[, c] == "/"] 
  cp[, c] <- as.numeric(sub(",", ".", as.character(cp[, c])))
}

summary(cp)

#Split place into comma separated entries
place <- strsplit(as.character(cp$Place), ",")
head(place)
max(sapply(place, length))

#Write separate entries to data frame
place_df <- lapply(place, function(i){
  p1 <- sub("^\\s+", "", i[1]) 
  if(length(i) > 2){
    p2 <- sub("^\\s+", "", i[2])
    p3 <- sub("^\\s+", "", i[3])
  } else if (length(i) > 1){
    p2 <- sub("^\\s+", "", i[2])
    p3 <- NA
  } else {
    p2 <- NA
    p3 <- NA
  }
  data.frame(A = p1,
             B = p2,
             C = p3)
})
place_df <- do.call("rbind", place_df)
place_df$ID <- cp$ID 
place_df$Year <- cp$Year 
head(place_df)

# Take care of "Landkreise"
for(r in seq(nrow(place_df))){
  if(is.na(place_df$B[r]) &
     grepl("kreis", tolower(place_df$A[r]))){
    place_df$B[r] <- "Landkreis"
  }
}
head(place_df)
unique(cp$Place[is.na(place_df$B)])
sum(is.na(place_df$B))

# Take care of federal states and country
place_df$B[is.na(place_df$B) & nchar(as.character(place_df$ID) == 2)] <- "Bundesland"
place_df$B[place_df$ID == "DG"] <- "Land"
head(place_df)

sum(is.na(place_df$B))

# Change names
names(place_df) <- c("Place", "Admin_unit", "Admin_misc", "ID", "Year")

# Merge the separated place information back into the original data frame
cp$Admin_unit <- c(0)
cp$Admin_misc <- c(0)
cp <- cp[c(1,2,3,8,9,4,5,6,7)]
cp[,3:5] <- place_df[,1:3]
head(cp)

saveRDS(cp, file = "C:/Users/Lena/Documents/Uni/Master Marburg/1. Semester/Datenanalyse/4.Stunde/flaechen.rds")
