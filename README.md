# LBSC
LBSC is a collection of small scripts for calculating Long-range Boundary (LB) scores and Short-range Compaction (SC) scores from Hi-C data. The input Hi-C data is expected to be in the map file format output by the rfy_hic2 package. For more information on the map file format, please refer to the demo files. 

# Hardware Requirement
The LBSC pipeline is designed for use in a Linux environment but can also be run on other operating systems with the appropriate setup.
The LBSC pipeline requires only a standard computer with sufficient RAM to support the operations defined by the user. For minimal performance, a computer with approximately 2 GB of RAM is recommended.

# Software Requirement
The following software is required to execute the LBSC pipeline. The versions listed in parentheses were used for verification during the creation of this pipeline: 

+ Git (version 2.34.1) -- A distributed version control system with speed and efficiency. https://git-scm.com/
+ Bash (version 5.1.16) -- A Unix shell and command language. https://www.gnu.org/software/bash/
+ R (version 4.1.2) -- A software environment for statistical computing and graphics. For installation examples, refer to Note 2. https://www.r-project.org/
+ KentUtils (20240611) -- A collection of utility programs for bioinformatics, primarily used for processing and analyzing genomic data  https://github.com/ENCODE-DCC/kentUtils


# Installin guide
The user can download the LBSC piepline using the command provided below:
```
git clone https://github.com/rafysta/LBSC.git
```
Pipeline will be install in a fseconds.


To install the necessary R packages for execution, run "install_libraries.R" as follows:

```
Rscript  install_libraries.R
```

Packages will be install in a few minutes.

# Demo
The demo data set was constructed by extracting a total of 1.5 million reads from processed Hi-C data (wt_pFA_MboI_Hi-C) of GSE270686. The data can be downloaded from the following link:  https://uo-cgf.s3.us-west-2.amazonaws.com/P/020/demo.map.gz

Example output from the test data is available in the demo_result folder. The running time for the LB score on the demo data is approximately 12 minutes. The running time for the SC score on the demo data is approximately a few seconds.

# Instructions for use
Example Commands for Calculating Scores
To calculate the LB score, use the following command:
```
sh LB.sh -i <map file> -o <output bedgraph> -c <chromosome size>
```

For more detailed instructions, run:
```
sh LB.sh --help
```

To calculate the SC score, use the following command:
```
sh SC.sh -i <map file> -o <output bedgraph> -c <chromosome size>
```

For more detailed instructions, run:
```
sh SC.sh --help
```

To calculate the difference between two LB scores, use the following command:
```
Rscript LB_diff.R --target <bedgraph of LB for target> --control <bedgraph of LB for control> --chrom_length <chromosome size> --outsimple <output bedgraph>
```

For more detailed instructions, run:
```
Rscript LB_diff.R --help
```

To calculate the difference between two SC scores, use the following command:
```
Rscript SC_diff.R --target <bedgraph of SC for target> --control <bedgraph of SC for control> --chrom_length <chromosome size> --outsimple <output bedgraph>
```

For more detailed instructions, run:
```
Rscript SC_diff.R --help
```
