#!/bin/bash
# SC score calculation

get_usage(){
	cat <<EOF

Usage : $0 [OPTION]

Description
	-h, --help
		show help

	-v, --version
		show version

	-i, --in [compressed map file(s)]
		map.gz file from rfy_hic2 package. If multiple file, quote by ". And insert space between files

	-o, --out [output bedgraph]
		output bedgraph

	-s, --shift [shift size ex 100bp]
		shift size. default 100bp

	-t, --threshold [distance threshold ex 2.5kb]
		distance threshold to distinguish long and short distance (default 2kb)

	-c, --chr [chromosome length file]
		chromosome length file
EOF

}

get_version(){
	echo "${0} version 1.0"
}

SHORT=hvi:o:s:t:c:
LONG=help,version,in:,out:,shift:,threshold:,chr:
PARSED=`getopt --options $SHORT --longoptions $LONG --name "$0" -- "$@"`
if [[ $? -ne 0 ]]; then
	exit 2
fi
eval set -- "$PARSED"

while true; do
	case "$1" in
		-h|--help)
			get_usage
			exit 1
			;;
		-v|--version)
			get_version
			exit 1
			;;
		-i|--in)
			FILE_MAP="$2"
			shift 2
			;;
		-o|--out)
			FILE_OUT="$2"
			shift 2
			;;
		-s|--shift)
			SHIFT_BP="$2"
			shift 2
			;;
		-t|--threshold)
			THRESHOLD="$2"
			shift 2
			;;
		-c|--chr)
			CHROM_SIZE="$2"
			shift 2
			;;
		--)
			shift
			break
			;;
		*)
			echo "Programming error"
			exit 3
			;;
	esac
done

DIR_LIB=$(dirname $0)
TIME_STAMP=$(date +"%Y-%m-%d_%H.%M.%S")
INPUT_FILES=$@

[ ! -n "${FILE_MAP}" ] && echo "Please specify map file" && exit 1
[ ! -n "${FILE_OUT}" ] && echo "Please specify output file" && exit 1
[ ! -n "${CHROM_SIZE}" ] && echo "Please specify chromosome length file" && exit 1

SHIFT_BP=${SHIFT_BP:-100}
THRESHOLD=${THRESHOLD:-2kb}

THRESHOLD=${THRESHOLD/Mb/000kb}
THRESHOLD=${THRESHOLD/kb/000}
SHIFT_BP=${SHIFT_BP/Mb/000kb}
SHIFT_BP=${SHIFT_BP/kb/000}

zcat ${FILE_MAP} | awk -v OFS='\t' -v tt=${THRESHOLD} -v ss=${SHIFT_BP} 'BEGIN{
	total=0;
	} $8=="U" && $15=="U" && $4==$11 && $5>=30 && $12>=30{
		distance=$10-$3;
		total++;
		b1=int($3/ss)*ss;
		b2=int($10/ss)*ss;
		if(distance < tt){
			chr=$2
			count[chr"\t"b1]++;
			count[chr"\t"b2]++;
		}
}END{
	printf "#total\t%d\n", total;
	printf "chr\tstart\tscore\n";
	for(x in count){
		print x,count[x]
	}
}' > ${FILE_OUT}_tmp


Rscript --vanilla --no-echo ${DIR_LIB}/Convert_SC_to_bedgraph.R -i ${FILE_OUT}_tmp -o ${FILE_OUT} -b ${SHIFT_BP} --chrom_length ${CHROM_SIZE}
