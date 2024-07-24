#!/usr/bin/Rscript
# calculate difference of LB score

suppressWarnings(suppressMessages(library(dplyr)))
suppressWarnings(suppressMessages(library(data.table)))
suppressWarnings(suppressMessages(library(pbapply)))

options(scipen=10)
options(dplyr.summarise.inform = FALSE)

suppressPackageStartupMessages(library("optparse"))
option_list <- list(  
  make_option(c("-a", "--target"), default="NA", help="targetのbedgraph"),
  make_option(c("-b", "--control"), default="NA", help="controlのbedgraph"),
  make_option(c("-o", "--out"), help="bedgraph file"),
  make_option(c("--outsimple"), default="NA", help="output without normalization"),
  make_option(c("--image"), default="NA", help="scatter plot image"),
  make_option(c("--chrom_length"), default="NA", help="chromosomal length file")
)
opt <- parse_args(OptionParser(option_list=option_list))

FILE_a <- as.character(opt["target"])
FILE_b <- as.character(opt["control"])
FILE_out <- as.character(opt["out"])
FILE_outsimple <- as.character(opt["outsimple"])
FILE_CHR <- as.character(opt["chrom_length"])
D_chr <- fread(FILE_CHR, col.names = c("chr", "length"))
FILE_image <- as.character(opt["image"])

df1 <- fread(FILE_a, header = FALSE, col.names = c("chr", "start", "end", "score")) %>% mutate(sample = "target")
df2 <- fread(FILE_b, header = FALSE, col.names = c("chr", "start", "end", "score")) %>% mutate(sample = "control")
D_data <- rbind(df1, df2)
D_data <- D_data %>% tidyr::spread(key=sample, value = score, fill=0)
D_data <- D_data %>% mutate(diff = target - control,ave = (target + control)/2)
model <- smooth.spline(D_data$ave, D_data$diff, nknots = 10, spar=0.2)
D_data <- D_data %>% mutate(predict=predict(model, x=D_data$ave)$y)
D_data <- D_data %>% mutate(diff.norm = diff - predict)
D_data <- D_data %>% arrange(chr, start)
D_data <- dplyr::left_join(D_data, D_chr, by="chr")
D_data <- D_data %>% filter(start > 0, end < length)

if(FILE_out != "NA"){
  write.table(D_data %>% select(chr, start, end, diff.norm), FILE_out, sep = "\t", row.names = FALSE, col.names = FALSE, quote = FALSE)
}
if(FILE_outsimple != "NA"){
  write.table(D_data %>% select(chr, start, end, diff), FILE_outsimple, sep = "\t", row.names = FALSE, col.names = FALSE, quote = FALSE)
}



if(FILE_image != "NA"){
  suppressWarnings(suppressMessages(library(ggplot2)))
  suppressWarnings(suppressMessages(library(cowplot)))
  
  p1 <- ggplot(D_data, aes(x=ave, y=diff)) +
    geom_hline(yintercept = 0) +
    geom_point(alpha=0.1, size = 2, stroke = 0, shape = 16) +
    geom_line(aes(y=predict), col='red') +
    theme_bw() +
    labs(y=paste0("Diff"))
  
  p2 <- ggplot(D_data, aes(x=ave, y=diff.norm)) +
    geom_hline(yintercept = 0) +
    geom_point(alpha=0.1, size = 2, stroke = 0, shape = 16) +
    theme_bw() +
    labs(y=paste0("Normalized Diff"))
  
  pmix <- ggarrange(p1, p2, heights = c(1, 1), ncol = 1, nrow = 2, align = "v")
  save_plot(FILE_image, pmix, base_width = 6, base_height = 10, dpi=100, unit="in")
}






