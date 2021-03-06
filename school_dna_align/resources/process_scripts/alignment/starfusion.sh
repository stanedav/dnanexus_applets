#!/bin/bash
#trimgalore.sh

usage() {
  echo "-h Help documentation for hisat.sh"
  echo "-r  --Reference Genome: GRCh38 or GRCm38"
  echo "-a  --FastQ R1"
  echo "-b  --FastQ R2"
  echo "-p  --Prefix for output file name"
  echo "Example: bash starfusion.sh -p prefix -r /project/shared/bicf_workflow_ref/human/GRCh38 -a SRR1551047_1.fastq.gz  -b SRR1551047_2.fastq.gz"
  exit 1
}
OPTIND=1 # Reset OPTIND
while getopts :r:a:b:p:m:fh opt
do
    case $opt in
        r) refgeno=$OPTARG;;
        a) fq1=$OPTARG;;
        b) fq2=$OPTARG;;
        p) pair_id=$OPTARG;;
	m) method=$OPTARG;;
	f) filter=1;;
        h) usage;;
    esac
done

shift $(($OPTIND -1))

# Check for mandatory options
if [[ -z $pair_id ]] || [[ -z $fq1 ]]; then
    usage
fi

if [[ -z $SLURM_CPUS_ON_NODE ]]
then
    SLURM_CPUS_ON_NODE=1
fi

baseDir="`dirname \"$0\"`"
source /etc/profile.d/modules.sh
module add python/2.7.x-anaconda star/2.5.2b bedtools/2.26.0

if [[ $method == 'trinity' ]]
then
    module load trinity/1.6.0
    tmphome="/tmp/$USER"
    if [[ -z $tmphome ]]
    then
	mkdir $tmphome
    fi 
    export TMP_HOME=$tmphome
    index_path=${refgeno}/CTAT_lib_trinity1.6
    trinity /usr/local/src/STAR-Fusion/STAR-Fusion --min_sum_frags 3 --CPU $SLURM_CPUS_ON_NODE --genome_lib_dir ${index_path} --left_fq ${fq1} --right_fq ${fq2} --examine_coding_effect --output_dir ${pair_id}_star_fusion
    #cp ${pair_id}_star_fusion/star-fusion.fusion_predictions.abridged.tsv ${pair_id}.starfusion.txt
    cp ${pair_id}_star_fusion/star-fusion.fusion_predictions.abridged.coding_effect.tsv ${pair_id}.starfusion.txt
else
    module add star/2.5.2b
    index_path=${refgeno}/CTAT_lib/
    STAR-Fusion --genome_lib_dir ${index_path} --min_sum_frags 3 --left_fq ${fq1} --right_fq ${fq2} --output_dir ${pair_id}_star_fusion &> star_fusion.err
    cp ${pair_id}_star_fusion/star-fusion.fusion_candidates.final.abridged ${pair_id}.starfusion.txt
fi

module load singularity/3.0.2
export PYENSEMBL_CACHE_DIR="/project/shared/bicf_workflow_ref/singularity_images"
cut -f 5-8 ${pair_id}.starfusion.txt |perl -pe 's/\^|:/\t/g' | awk '{print "singularity exec /project/shared/bicf_workflow_ref/singularity_images/agfusion.simg agfusion annotate  -db  /project/shared/bicf_workflow_ref/singularity_images/pyensembl/GRCh38/ensembl92/agfusion.homo_sapiens.92.db -g5", $1,"-j5",$4,"-g3",$6,"-j3",$9,"-o",$1"_"$4"_"$6"_"$9}' |grep -v 'LeftGene' |sh

if [[ $filter == 1 ]]
then
    cut -f 6,8 ${pair_id}.starfusion.txt |grep -v Breakpoint |perl -pe 's/\t/\n/g' |awk -F ':' '{print $1"\t"$2-1"\t"$2}' > temp.bed
    bedtools intersect -wao -a temp.bed -b /project/shared/bicf_workflow_ref/human/GRCh38/cytoBand.txt |cut -f 1,2,7 > cytoband_pos.txt
    perl $baseDir/filter_genefusions.pl -p ${pair_id} -f ${pair_id}.starfusion.txt
fi


