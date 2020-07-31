#!/bin/bash
# rnaalign 0.5.31
# Generated by dx-app-wizard.

main() {

    dx download "$fq1" -o seq.R1.fastq.gz
    dx download "$fq2" -o seq.R2.fastq.gz
    dx download "$reference" -o rnaref.tar.gz

    mkdir rnaref
    docker run -v ${PWD}:/data docker.io/goalconsortium/ralign:0.5.31 tar -I pigz -xvf rnaref.tar.gz --strip-components=1 -C rnaref

    umiopt=""
    if [[ ${mdup} == 'fgbio_umi' ]]
    then
	umiopt=" -u"
    fi

    docker run -v ${PWD}:/data docker.io/goalconsortium/trim_galore:0.5.31 -f -p ${pair_id} seq.R1.fastq.gz seq.R2.fastq.gz
    docker run -v ${PWD}:/data docker.io/goalconsortium/ralign:0.5.31 bash /seqprg/school/process_scripts/alignment/rnaseqalign.sh -a ${aligner} -p ${pair_id} -r rnaref -x ${pair_id}.trim.R1.fastq.gz -y ${pair_id}.trim.R2.fastq.gz $umiopt

    trim1=$(dx upload ${pair_id}.trim.R1.fastq.gz --brief)
    trim2=$(dx upload ${pair_id}.trim.R2.fastq.gz --brief)
    trimreport=$(dx upload ${pair_id}.trimreport.txt --brief)
    bam=$(dx upload ${pair_id}.bam --brief)
    bai=$(dx upload ${pair_id}.bam.bai --brief)
    alignstats=$(dx upload ${pair_id}.alignerout.txt --brief)

    dx-jobutil-add-output trim1 "$trim1" --class=file
    dx-jobutil-add-output trim2 "$trim2" --class=file
    dx-jobutil-add-output trimreport "$trimreport" --class=file
    dx-jobutil-add-output bam "$bam" --class=file
    dx-jobutil-add-output bai "$bai" --class=file
    dx-jobutil-add-output alignstats "$alignstats" --class=file
}
