#!/bin/bash
# Structural_Variants 0.0.1
# Generated by dx-app-wizard.

main() {

    dx download "$Raw_Tumor_BAM" -o raw.tumor.bam
    dx download "$Consensus_Tumor_BAM" -o consensus.tumor.bam
    dx download "$reference" -o dnaref.tar.gz

    tar xvfz dnaref.tar.gz

    if [ -n "$Raw_Normal_BAM" ]
    then
        dx download "$Raw_Normal_BAM" -o raw.normal.bam
    fi
    if [ -n "$Consensus_Normal_BAM" ]
    then
        dx download "$Consensus_Normal_BAM" -o consensus.normal.bam
    fi

    docker run -v ${PWD}:/data docker.io/goalconsortium/variantcalling:1.0.0 bash /usr/local/bin/indexbams.sh

    if [[ "${algo}" == "pindel" ]]
    then
        if [[ -z "$Consensus_Normal_BAM" ]]
        then
            docker run -v ${PWD}:/data docker.io/goalconsortium/structuralvariant:1.0.0 bash /usr/local/bin/svcalling.sh -r dnaref -b consensus.tumor.bam -p ${pair_id} -l dnaref/itd_genes.bed -a ${algo} -f
        else
             docker run -v ${PWD}:/data docker.io/goalconsortium/structuralvariant:1.0.0 bash /usr/local/bin/svcalling.sh -r dnaref -p ${pair_id} -l dnaref/itd_genes.bed -a ${algo} -f
        fi

    elif [[ "${algo}" == "checkmates" ]]
    then
        docker run -v ${PWD}:/data docker.io/goalconsortium/vcfannot:1.0.0 python /usr/local/bin/ncm.py -B -d ./ -bed dnaref/NGSCheckMate.bed -O ./ -N ${pair_id}
        docker run -v ${PWD}:/data docker.io/goalconsortium/vcfannot:1.0.0 perl /usr/local/bin/sequenceqc_somatic.pl -r dnaref -i ${pair_id}_all.txt -o ${pair_id}.sequence.stats.txt

    else
        if [[ -z "$Raw_Normal_BAM" ]]
        then
            docker run -v ${PWD}:/data docker.io/goalconsortium/structuralvariant:1.0.0 bash /usr/local/bin/svcalling.sh -r dnaref -b raw.tumor.bam -p ${pair_id} -a ${algo} -f
        else
            docker run -v ${PWD}:/data docker.io/goalconsortium/structuralvariant:1.0.0 bash /usr/local/bin/svcalling.sh -r dnaref -x 'tumor' -y 'normal' -b raw.tumor.bam -n raw.normal.bam -p ${pair_id} -a ${algo} -f
        fi
    fi

    if [[ "${algo}" == "checkmates" ]]
    then
        matched=$(dx upload ${pair_id}_matched.txt --brief)
        all=$(dx upload ${pair_id}_all.txt --brief)

        dx-jobutil-add-output matched "$matched" --class=file
        dx-jobutil-add-output all "$all" --class=file
    elif [[ "${algo}" == "pindel" ]]
    then
        vcf=$(dx upload ${pair_id}.${algo}.vcf.gz --brief)
        svvcf=$(dx upload ${pair_id}.${algo}.sv.vcf.gz --brief)
        tdvcf=$(dx upload ${pair_id}.${algo}_tandemdup.vcf.gz --brief)
        genefusion=$(dx upload ${pair_id}.${algo}.genefusion.txt --brief)

        dx-jobutil-add-output vcf "$vcf" --class=file
        dx-jobutil-add-output svvcf "$svvcf" --class=file
        dx-jobutil-add-output tdvcf "$tdvcf" --class=file
        dx-jobutil-add-output genefusion "$genefusion" --class=file
    elif [[ "${algo}" == "delly" ]]
    then
        vcf=$(dx upload ${pair_id}.${algo}.vcf.gz --brief)
        genefusion=$(dx upload ${pair_id}.${algo}.genefusion.txt --brief)

        dx-jobutil-add-output vcf "$vcf" --class=file
        dx-jobutil-add-output genefusion "$genefusion" --class=file
    else
        vcf=$(dx upload ${pair_id}.${algo}.vcf.gz --brief)
        svvcf=$(dx upload ${pair_id}.${algo}.sv.vcf.gz --brief)
        genefusion=$(dx upload ${pair_id}.${algo}.genefusion.txt --brief)

        dx-jobutil-add-output vcf "$vcf" --class=file
        dx-jobutil-add-output svvcf "$svvcf" --class=file
        dx-jobutil-add-output genefusion "$genefusion" --class=file
    fi
}
