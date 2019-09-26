#!/bin/bash
# QC_BAM 0.0.1
# Generated by dx-app-wizard.
#
# Basic execution pattern: Your app will run on a single machine from
# beginning to end.
#
# Your job's input variables (if any) will be loaded as environment
# variables before this script runs.  Any array inputs will be loaded
# as bash arrays.
#
# Any code outside of main() (or any entry point you may add) is
# ALWAYS executed, followed by running the entry point itself.
#
# See https://wiki.dnanexus.com/Developer-Portal for tutorials on how
# to modify this file.

main() {

    echo "Value of Consensus_BAM: '$Consensus_BAM'"
    echo "Value of reference_files: '$reference_files'"
    echo "Value of pair_id: '$pair_id'"

    # The following line(s) use the dx command-line tool to download your file
    # inputs to the local file system using variable names for the filenames. To
    # recover the original filenames, you can use the output of "dx describe
    # "$variable" --name".

    dx download "$Consensus_BAM" -o consensus.bam
    dx download "$reference_files" -o reference.tar.gz

    if [[ -z $pair_id ]]
    then
        pair_id='seq'
    fi
    echo "Value of pair_id: '$pair_id'"

    tar xvfz reference.tar.gz
    gunzip reference/genome.fa.gz

    docker run -v ${PWD}:/data docker.io/bcantarel/alignment:v1 samtools view -@ 1 -b -L hemepanelV3.bed -o ${pair_id}.ontarget.bam consensus.bam
    docker run -v ${PWD}:/data docker.io/bcantarel/alignment:v1 samtools index -@ 1 ${pair_id}.ontarget.bam
    docker run -v ${PWD}:/data docker.io/bcantarel/alignment:v1 samtools flagstat ${pair_id}.ontarget.bam > ${pair_id}.ontarget.flagstat.txt
    docker run -v ${PWD}:/data docker.io/bcantarel/alignment:v1 java -Xmx64g -jar /usr/local/bin/picard.jar CollectAlignmentSummaryMetrics R=reference/genome.fa I=${pair_id}.ontarget.bam OUTPUT=${pair_id}.alignmentsummarymetrics.txt
    docker run -v ${PWD}:/data docker.io/bcantarel/alignment:v1 java -Xmx64g -XX:ParallelGCThreads=1 -jar /usr/local/bin/picard.jar EstimateLibraryComplexity I=consensus.bam OUTPUT=${pair_id}.libcomplex.txt
    docker run -v ${PWD}:/data docker.io/bcantarel/alignment:v1 samtools view  -@ 1 -b -q 1 consensus.bam | docker run -v ${PWD}:/data docker.io/bcantarel/alignment:v1 bedtools coverage -sorted -hist -g reference/genomefile.txt -b stdin -a hemepanelV3.bed > ${pair_id}.mapqualcov.txt
    docker run -v ${PWD}:/data docker.io/bcantarel/alignment:v1 samtools view  -@ 1 consensus.bam | awk '{sum+=$5} END { print "Mean MAPQ =",sum/NR}' > ${pair_id}.meanmap.txt

    docker run -v ${PWD}:/data docker.io/bcantarel/alignment:v1 java -Xmx64g -jar /usr/local/bin/picard.jar CollectInsertSizeMetrics INPUT=consensus.bam HISTOGRAM_FILE=${pair_id}.hist.ps REFERENCE_SEQUENCE=reference/genome.fa OUTPUT=${pair_id}.hist.txt
    docker run -v ${PWD}:/data docker.io/bcantarel/alignment:v1 bedtools coverage -sorted -g  reference/genomefile.txt -a hemepanelV3.bed -b consensus.bam -hist > ${pair_id}.covhist.txt
    docker run -v ${PWD}:/data docker.io/bcantarel/alignment:v1 grep ^all ${pair_id}.covhist.txt >  ${pair_id}.genomecov.txt


    umihist=$(dx upload ${pair_id}.hist.txt --brief)
    dedupcov=$(dx upload ${pair_id}.genomecov.txt --brief)
    covuniqhist=$(dx upload ${pair_id}.covhist.txt --brief)


    dx-jobutil-add-output umihist "$umihist" --class=file
    dx-jobutil-add-output dedupcov "$dedupcov" --class=file
    dx-jobutil-add-output covuniqhist "$covuniqhist" --class=file
}
