#!/bin/bash
# LB score calcualtion
# score = (intra upstream xxbp + intra downstream xxbp) / (inter upstream xxp vs downstream xxbp x2)

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

	-o, --out [output file]
		output file

	-b, --bw [bigwig output file]
		bigwig file name if output

	-r, --resolution [resolution ex 1kb]
		resolution of the analysis (default 100)

	--max [maximum distance for calculation ex 500kb]
		maximum distance to consider (default 500kb)

	--min [minimum distance for calcualtion ex 100kb]
		minimum distane to consider (default 100kb)

	-c, --chr [chromosome length file]
		chromosome length file
EOF

}

get_version(){
	echo "${0} version 1.0"
}

SHORT=hvi:o:b:r:c:
LONG=help,version,in:,out:,bw:,resolution:,max:,min:,chr:
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
		-b|--bw)
			FILE_BIGWIG="$2"
			shift 2
			;;
		-r|--resolution)
			RESOLUTION="$2"
			shift 2
			;;
		--max)
			THRESHOLD_MAX="$2"
			shift 2
			;;
		--min)
			THRESHOLD_MIN="$2"
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

[ ! -n "${FILE_MAP}" ] && echo "Please specify map file from rfy_hic2 package" && exit 1
[ ! -n "${FILE_OUT}" ] && echo "Please specify output file" && exit 1
[ ! -n "${CHROM_SIZE}" ] && echo "Please specify chromosome length file" && exit 1

RESOLUTION=${RESOLUTION:-100}
THRESHOLD_MIN=${THRESHOLD_MIN:-100kb}
THRESHOLD_MAX=${THRESHOLD_MAX:-500kb}

RESOLUTION=${RESOLUTION/Mb/000kb}
RESOLUTION=${RESOLUTION/kb/000}
THRESHOLD_MAX=${THRESHOLD_MAX/Mb/000kb}
THRESHOLD_MAX=${THRESHOLD_MAX/kb/000}
THRESHOLD_MIN=${THRESHOLD_MIN/Mb/000kb}
THRESHOLD_MIN=${THRESHOLD_MIN/kb/000}

zcat ${FILE_MAP} | awk -v OFS='\t' -v tt_min=${THRESHOLD_MIN} -v tt_max=${THRESHOLD_MAX} -v rr=${RESOLUTION} '
$2 == $9 && $8=="U" && $15=="U" && $4==$11 && $5>=30 && $12>=30 && $10-$3<=tt_max && $10-$3>=tt_min {
	for(s=$3-tt_max; s<$10+tt_max; s+=rr){
		s1=int(s/rr)*rr;
		s2=s1+rr-1
		if($10 < s || s < $3){
			intra[$2"\t"s1"\t"s2]++;
		}else{
			inter[$2"\t"s1"\t"s2]++;
		}
	}
}END{
	for(x in intra){
		n_intra=intra[x]
		if(x in inter){
			n_inter=inter[x];
		}else{
			n_inter=0;
		}
		score= 1- n_inter * 2 / n_intra;
		print x,score;
	}
}' > ${FILE_OUT}.score


awk -v OFS='\t' 'NR==FNR{
	LEN[$1]=$2;next
}$2 > 0 && $3<LEN[$1]{
	print
}' ${CHROM_SIZE} ${FILE_OUT}.score > ${FILE_OUT}.score.trim

sort -k1,1 -k2,2n ${FILE_OUT}.score.trim > ${FILE_OUT}


# module load Kent_tools
[ -n $FILE_BIGWIG ] && bedGraphToBigWig ${FILE_OUT} ${CHROM_SIZE} $FILE_BIGWIG

[ -e ${FILE_OUT} ] && rm -f ${FILE_OUT}.score ${FILE_OUT}.score.trim
