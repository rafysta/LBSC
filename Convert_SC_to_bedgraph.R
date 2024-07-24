#!/usr/bin/Rscript
# Convert Sc score to bedgraph

suppressWarnings(suppressMessages(library(dplyr)))
suppressWarnings(suppressMessages(library(data.table)))
options(scipen=10)
options(dplyr.summarise.inform = FALSE)

suppressPackageStartupMessages(library("optparse"))
option_list <- list(  
  make_option(c("-i", "--in"), help="output from SC.sh"),
  make_option(c("-o", "--out"), help="bedgraph file"),
  make_option(c("-b", "--bin"), default="500", help="bin size"),
  make_option(c("--chrom_length"), default="NA", help="chromosomal length file")
)
opt <- parse_args(OptionParser(option_list=option_list))


FILE_in <- as.character(opt["in"])
FILE_out <- as.character(opt["out"])
FILE_CHR <- as.character(opt["chrom_length"])
D_chr <- fread(FILE_CHR, col.names = c("chr", "length"))
CHR_LENGTH <- sum(D_chr %>% pull(length))
BIN_SIZE <- as.numeric(as.character(opt["bin"]))

df <- fread(FILE_in, nrows = 1, col.names = c("dummy", "total"))
total_read <- df$total
D_data <- fread(FILE_in, skip = 1, header = TRUE)
D_data <- D_data %>% mutate(score.norm = score / total_read * (CHR_LENGTH / 100))
D_data <- D_data %>% mutate(end = start + BIN_SIZE)
D_data <- D_data %>% arrange(chr, start)

D_data <- dplyr::left_join(D_data, D_chr, by="chr")
D_data <- D_data %>% filter(start > 0, end < length)

write.table(D_data %>% select(chr, start, end, score.norm), FILE_out, sep = "\t", row.names = FALSE, col.names = FALSE, quote = FALSE)
