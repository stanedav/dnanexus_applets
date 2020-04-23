#!/bin/bash
# Structural_Variants 0.0.1
# Generated by dx-app-wizard.

main() {


    dx download "$Tumor_BAM" -o ${pair_id}.tumor.bam
    dx download "$reference" -o dnaref.tar.gz

    tar xvfz dnaref.tar.gz

    if [ -n "$Normal_BAM" ]
    then
        dx download "$Normal_BAM" -o ${pair_id}.normal.bam
    fi

    docker run -v ${PWD}:/data docker.io/goalconsortium/variantcalling:1.0.0 bash /usr/local/bin/indexbams.sh

    if [[ "${algo}" == "pindel" ]]
    then
        if [[ -z "$Normal_BAM" ]]
        then
            docker run -v ${PWD}:/data docker.io/goalconsortium/structuralvariant:1.0.0 bash /usr/local/bin/svcalling.sh -r dnaref -b ${pair_id}.tumor.bam -p ${pair_id} -l dnaref/itd_genes.bed -a ${algo} -f
        else
             docker run -v ${PWD}:/data docker.io/goalconsortium/structuralvariant:1.0.0 bash /usr/local/bin/svcalling.sh -r dnaref -p ${pair_id} -l dnaref/itd_genes.bed -a ${algo} -f
        fi

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
        if [[ -z "$Normal_BAM" ]]
        then
            docker run -v ${PWD}:/data docker.io/goalconsortium/structuralvariant:1.0.0 bash /usr/local/bin/svcalling.sh -r dnaref -b ${pair_id}.tumor.bam -p ${pair_id} -a ${algo} -f
        else
            docker run -v ${PWD}:/data docker.io/goalconsortium/structuralvariant:1.0.0 bash /usr/local/bin/svcalling.sh -r dnaref -x 'tumor' -y 'normal' -b ${pair_id}.tumor.bam -n ${pair_id}.normal.bam -p ${pair_id} -a ${algo} -f
        fi

        vcf=$(dx upload ${pair_id}.${algo}.vcf.gz --brief)
        genefusion=$(dx upload ${pair_id}.${algo}.genefusion.txt --brief)

        dx-jobutil-add-output vcf "$vcf" --class=file
        dx-jobutil-add-output genefusion "$genefusion" --class=file 

    elif [[ "${algo}" == "svaba" ]]
    then
        if [[ -z "$Normal_BAM" ]]
        then
            docker run -v ${PWD}:/data docker.io/goalconsortium/structuralvariant:1.0.0 bash /usr/local/bin/svcalling.sh -r dnaref -b ${pair_id}.tumor.bam -p ${pair_id} -a ${algo} -f
        else
            docker run -v ${PWD}:/data docker.io/goalconsortium/structuralvariant:1.0.0 bash /usr/local/bin/svcalling.sh -r dnaref -x 'tumor' -y 'normal' -b ${pair_id}.tumor.bam -n ${pair_id}.normal.bam -p ${pair_id} -a ${algo} -f
        fi

        vcf=$(dx upload ${pair_id}.${algo}.vcf.gz --brief)
        svvcf=$(dx upload ${pair_id}.${algo}.sv.vcf.gz --brief)
        genefusion=$(dx upload ${pair_id}.${algo}.genefusion.txt --brief)

        dx-jobutil-add-output vcf "$vcf" --class=file
        dx-jobutil-add-output svvcf "$svvcf" --class=file
        dx-jobutil-add-output genefusion "$genefusion" --class=file

    elif [[ "${algo}" == "checkmates" ]]
    then
        docker run -v ${PWD}:/data docker.io/goalconsortium/vcfannot:1.0.0 python /usr/local/bin/ncm.py -B -d ./ -bed dnaref/NGSCheckMate.bed -O ./ -N ${pair_id}
        docker run -v ${PWD}:/data docker.io/goalconsortium/vcfannot:1.0.0 perl /usr/local/bin/sequenceqc_somatic.pl -r dnaref -i ${pair_id}_all.txt -o ${pair_id}.sequence.stats.txt

        matched=$(dx upload ${pair_id}_matched.txt --brief)
        all=$(dx upload ${pair_id}_all.txt --brief)

        dx-jobutil-add-output matched "$matched" --class=file
        dx-jobutil-add-output all "$all" --class=file

    else
        echo "Incorrect algorithm selection. Please select 1 of the following algorithms: pindel, delly, svaba, checkmates"
    fi
}
