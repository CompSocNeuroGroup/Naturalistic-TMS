library(plyr) # for data wrangling
library(readr) # for reading multiple csv files
library(dplyr) # for piping
library(data.table) # for conditional value replacing
library(stringr)

setwd("/home/jthompsz/data/Naturalistic/textfiles/")
mydir = "c001"
outdir = "c001/textfiles"
locfiles = list.files(path = mydir, 
                     pattern = "*.csv", 
                     full.names = TRUE)
myfiles <- str_subset(locfiles, "localizer_")
dur <- c(16,16,16)
weight <-c(1,1,1)
runs<-c("run1", "run2")
#runs<-c("run1")
conditions<-c("people", "places", "objects", "food", "scrambled")
loc_files <- str_subset(myfiles, "localizer")
for (run in 1:length(runs)) {
  dat_csv = ldply(myfiles[run], read_csv)
  for (conds in conditions) {
    dat<-subset(dat_csv, block==conds)
    tmp<-as.data.frame(dat$`block start`)
    tmp$dur<-dur
    tmp$weight<-weight
    write.table(tmp, file=paste0(outdir, "/", runs[run], "-", conds, ".tsv"), row.names=FALSE, col.names=FALSE, sep="\t")
    rm(tmp)
    rm(dat)
  }

}
