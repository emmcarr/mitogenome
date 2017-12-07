## bash scripts for the pipeline in the main file
## to be done after indexing of reference file

## FILE 1
#!/bin/bash 
#$ -cwd 
#$ -j y
#$ -S /bin/bash 
#$ -V
#$ -N TrimWA ## job name

module load trimmomatic
## trimming using trimmomatic
java -jar /usr/local/Modules/modulefiles/tools/trimmomatic/0.32/bin/trimmomatic-0.32.jar PE -threads 6 -phred33 \
/storage/home/users/elc6/genome/data/Sample_7/7-Eau94WA04_S7_L004_R1_001.fastq.gz \
/storage/home/users/elc6/genome/data/Sample_7/7-Eau94WA04_S7_L004_R2_001.fastq.gz \
/storage/home/users/elc6/genome/QCdata/Eau94WA04_forward_paired.fq \
/storage/home/users/elc6/genome/QCdata/Eau94WA04_forward_unpaired.fq \
/storage/home/users/elc6/genome/QCdata/Eau94WA04_reverse_paired.fq \
/storage/home/users/elc6/genome/QCdata/Eau94WA04_reverse_unpaired.fq \
LEADING:3 TRAILING:3 SLIDINGWINDOW:4:15 MINLEN:75

### FILE 2
#!/bin/bash 
#$ -cwd 
#$ -j y
#$ -S /bin/bash 
#$ -V
#$ -N aln9404 ## job name

module load bwa
module load samtools/1.5
module load bcftools/1.5
module load picard-tools

## merge trimmed files

cat  /storage/home/users/elc6/genome/QCdata/Eau94WA04_forward_paired.fq \
/storage/home/users/elc6/genome/QCdata/Eau94WA04_forward_unpaired.fq \
/storage/home/users/elc6/genome/QCdata/Eau94WA04_reverse_paired.fq \
/storage/home/users/elc6/genome/QCdata/Eau94WA04_reverse_unpaired.fq > /storage/home/users/elc6/genome/mitogenome_analysis/Eau94WA04cat.fq

## align against mitogenome reference
bwa mem /storage/home/users/elc6/genome/QCdata/AImitogen/AImito \
	/storage/home/users/elc6/genome/mitogenome_analysis/Eau94WA04cat.fq > /storage/home/users/elc6/genome/mitogenome_analysis/Eau94WA04aln.sam

## convert to bam
samtools view -h -S -b /storage/home/users/elc6/genome/mitogenome_analysis/Eau94WA04aln.sam > /storage/home/users/elc6/genome/mitogenome_analysis/Eau94WA04aln.bam

## only use high quality mapped reads
samtools view -b -F 4 -q 30 /storage/home/users/elc6/genome/mitogenome_analysis/Eau94WA04aln.bam > /storage/home/users/elc6/genome/mitogenome_analysis/Eau94WA04alnQC.bam

## sort reads
samtools sort /storage/home/users/elc6/genome/mitogenome_analysis/Eau94WA04alnQC.bam \
 -o /storage/home/users/elc6/genome/mitogenome_analysis/Eau94WA04alnSortQC.bam
 
## use picard to add read groups and take out duplicates
java -jar /usr/local/Modules/modulefiles/tools/picard-tools/2.14.1/picard.jar MarkDuplicates \
	INPUT= /storage/home/users/elc6/genome/mitogenome_analysis/Eau94WA04alnSortQC.bam \
	OUTPUT= /storage/home/users/elc6/genome/mitogenome_analysis/Eau94WA04alnSortQCUniq.bam \
	REMOVE_DUPLICATES=true \
	METRICS_FILE=output.dup_metrics \
	CREATE_INDEX=TRUE \
	VALIDATION_STRINGENCY=SILENT

java -jar /usr/local/Modules/modulefiles/tools/picard-tools/2.14.1/picard.jar AddOrReplaceReadGroups \
      I=/storage/home/users/elc6/genome/mitogenome_analysis/Eau94WA04alnSortQCUniq.bam \
      O=/storage/home/users/elc6/genome/mitogenome_analysis/Eau94WA04alnSortQCUniqRG.bam \
      RGID=HJF3HB \
      RGLB=Eau09AI050lib1 \
     RGPU=HJF3HBBXX \
      RGPL=illumina \
      RGSM=Eau94WA04
      
samtools mpileup -uf /storage/home/users/elc6/genome/QCdata/AImitogen/AImito.fasta \
/storage/home/users/elc6/genome/mitogenome_analysis/Eau94WA04alnSortQCUniqRG.bam | bcftools call -c | vcfutils.pl vcf2fq > /storage/home/users/elc6/genome/mitogenome_analysis/Eau94WA04cns.fq
