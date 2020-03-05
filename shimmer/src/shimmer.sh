#!/bin/bash
# shimmer 0.0.1
# Generated by dx-app-wizard.

main() {

    dx download "$Consensus_Tumor_BAM" -o tumor.bam
    dx download "$Consensus_Normal_BAM" -o normal.bam
    dx download "$reference" -o dnaref.tar.gz

    tar xvfz dnaref.tar.gz

    docker run -v ${PWD}:/data docker.io/goalconsortium/variantcalling:v1 bash /usr/local/bin/indexbams.sh
    docker run -v ${PWD}:/data docker.io/goalconsortium/variantcalling:v1 bash /usr/local/bin/somatic_vc.sh -r dnaref -p ${pair_id} -x 'tumor' -y 'normal' -n normal.bam -t tumor.bam -a shimmer
    docker run -v ${PWD}:/data docker.io/goalconsortium/variantcalling:v1 bash /usr/local/bin/uni_norm_annot.sh -g 'GRCh38.92' -r dnaref -p ${pair_id}.shimmer -v ${pair_id}.shimmer.vcf.gz

    shimmer_vcf=$(dx upload ${pair_id}.shimmer.vcf.gz --brief)
    
    dx-jobutil-add-output shimmer_vcf "$shimmer_vcf" --class=file
}
