#!/bin/bash
#union.sh

usage() {
  echo "-h Help documentation for gatkrunner.sh"
  echo "-r  --Reference Genome: GRCh38 or GRCm38"
  echo "-p  --Prefix for output file name"
  echo "Example: bash union.sh -p prefix -r /path/GRCh38"
  exit 1
}
OPTIND=1 # Reset OPTIND
while getopts :r:d:p:h opt
do
    case $opt in
        r) index_path=$OPTARG;;
        p) pair_id=$OPTARG;;
        d) dir=$OPTARG;;
        h) usage;;
    esac
done
function join_by { local IFS="$1"; shift; echo "$*"; }
shift $(($OPTIND -1))
baseDir="`dirname \"$0\"`"

echo $pair_id $index_path $dir

if [[ -z $dir ]]
then
dir='.'
fi

source /etc/profile.d/modules.sh
module load bedtools/2.26.0 samtools/1.6 bcftools/1.6 snpeff/4.3q

HS=${dir}/*.hotspot.vcf.gz
list1=`ls ${dir}/*vcf.gz|grep -v hotspot`
list2=`ls ${dir}/*vcf.gz|grep -v hotspot`
varlist=''
calllist=''
for i in ${dir}/*.vcf.gz; do
    if [[ $i == $HS ]]
    then
	bcftools norm -m - -O z -o hotspot.norm.vcf.gz $i
	java -jar /cm/shared/apps/snpeff/4.3q/SnpSift.jar filter "(GEN[*].AD[1] > 3)" hotspot.norm.vcf.gz |bgzip > hotspot.lowfilt.vcf.gz
	bedtools multiinter -i $list1 |cut -f 1,2,3 |bedtools intersect -header -v -a hotspot.lowfilt.vcf.gz -b stdin |bgzip > nooverlap.hotspot.vcf.gz
	list2="$list2 nooverlap.hotspot.vcf.gz"
    fi
done 

perl $baseDir/unionvcf.pl ${index_path}/union.header.vcf $list2
perl $baseDir/vcfsorter.pl ${index_path}/genome.dict int.vcf |bgzip > ${pair_id}.union.vcf.gz

