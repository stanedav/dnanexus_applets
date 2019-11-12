#!/bin/bash
# mutect2 0.0.1
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
# See https://documentation.dnanexus.com/developer for tutorials on how
# to modify this file.

main() {

    # The following line(s) use the dx command-line tool to download your file
    # inputs to the local file system using variable names for the filenames. To
    # recover the original filenames, you can use the output of "dx describe
    # "$variable" --name".

    dx download "$GATK_tumor_bam" -o tumor.bam
    dx download "$GATK_tumor_bam_index" -o tumor.bam.bai
    dx download "$GATK_normal_bam" -o normal.bam
    dx download "$GATK_normal_bam_index" -o normal.bam.bai

    dx download "$ref_file" -o reference.tar.gz

    tar xvfz reference.tar.gz
    gunzip reference/genome.fa.gz

    docker run -v ${PWD}:/data docker.io/goalconsortium/gatk:v1 java -XX:ParallelGCThreads=1 -Xmx16g -jar /usr/local/bin/picard.jar CollectSequencingArtifactMetrics I=tumor.bam O=artifact_metrics.txt R=reference/genome.fa
    docker run -v ${PWD}:/data docker.io/goalconsortium/gatk:v1 sh -c "gatk --java-options \"-Xmx20g\" Mutect2 -R reference/genome.fa -A FisherStrand -A QualByDepth -A DepthPerAlleleBySample -I tumor.bam -tumor Tumor -I normal.bam -normal Normal --output ${pair_id}.mutect.vcf"
    docker run -v ${PWD}:/data docker.io/goalconsortium/gatk:v1 sh -c "gatk --java-options \"-Xmx20g\" FilterMutectCalls -V ${pair_id}.mutect.vcf -R reference/genome.fa -O ${pair_id}.mutect.filt.vcf"
    docker run -v ${PWD}:/data docker.io/goalconsortium/gatk:v1 sh -c "vcf-sort ${pair_id}.mutect.filt.vcf | vcf-annotate -n --fill-type | java -jar /usr/local/bin/snpEff/SnpSift.jar filter -p '(GEN[*].DP >= 10)' | bgzip > ${pair_id}.mutect.vcf.gz"

    mutect_vcf=$(dx upload ${pair_id}.mutect.vcf.gz --brief)

    # The following line(s) use the utility dx-jobutil-add-output to format and
    # add output variables to your job's output as appropriate for the output
    # class.  Run "dx-jobutil-add-output -h" for more information on what it
    # does.

    dx-jobutil-add-output mutect_vcf "$mutect_vcf" --class=file
}
