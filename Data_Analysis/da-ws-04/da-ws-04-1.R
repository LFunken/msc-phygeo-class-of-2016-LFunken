cp <- read.table("C:/Users/Lena/Documents/Uni/Master Marburg/1. Semester/Datenanalyse/4.Stunde/115-46-4_feldfruechte.txt",
                 skip = 6, header = TRUE, sep = ";", dec = ",",
                 fill = TRUE, encoding="ANSI")

head(cp)

str(cp)

#New column names
names(cp) <- c("Year", "ID", "Place", "Winter_wheat", "Rye", "Winter_barley",
               "Spring_barley", "Oat", "Triticale", "Potatoes", "Suggar_Beets",
               "Rapeseed", "Silage_maize")

#Cut off tail
tail(cp)
cp <- cp[1:8925,]

# Numbers as numbers, not characters/factors
for(c in colnames(cp)[4:13]){
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

unique(place_df[,2]) 
unique(place_df[,3])
unique(place_df[,1])
unique(place_df$B[!is.na(place_df$C)]) 

# Swap second and third column
place_df[!is.na(place_df$C),] <- place_df[!is.na(place_df$C), c(1,3,2,4,5)]

unique(cp$Place[is.na(place_df$B)])
sum(is.na(place_df$B))

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

# Merge the separated place information back into the original data frame
cp$Admin_unit <- c(0)
cp$Admin_misc <- c(0)
cp <- cp[c(1,2,3,14,15,4,5,6,7,8,9,10,11,12,13)]
cp[,3:5] <- place_df
head(cp)

saveRDS(cp, file = "C:/Users/Lena/Documents/Uni/Master Marburg/1. Semester/Datenanalyse/4.Stunde/fruechte.rds")
