<!-- dx-header -->
# Mark Duplicates
markdups

## Options
- samtools markdup
- picard Picard MarkDuplicates
- picard_umi Picard MarkDuplicates BARCODE_TAG=RX 
- fgbio_umi GroupReadsByUmi, CallMolecularConsensusReads 

## Uses
- Docker Container [goalconsortium/alignment](https://hub.docker.com/repository/docker/goalconsortium/alignment/general)
- Git Repo [SCHOOL](https://github.com/bcantarel/school)

**Input**
- Sorted BAM
- Sorted BAM BAI
- PairID: SampleName/ReadGroup
- MarkDup Method
  - samtools
  - picard
  - picard_umi
  - fgbio_umi
- Human Ref
  - BWA Index Files for the Human Genome, required for fgbio_umi

**Output**
- Sorted BAM
- BAM BAI,


**Reference File Creation**

Human Ref:
```
mkdir humanref
cp GRCh38.fa humanref/genome.fa
cd humanref
bwa index -a bwtsw genome.fa
cd ..
tar cfz humanref.tar.gz humaref
```
