#!/bin/bash
set -x
SVABA=~/app/svaba/src/svaba/svaba
CONFIGMANTA=~/miniconda3/envs/manta/bin/configManta.py
SAMTOOLS=~/app/samtools/bin/samtools
BCFTOOLS=~/app/bcftools/bin/bcftools
LUMPY_EXPRESS=~/app/lumpy-sv/bin/lumpyexpress
SVTYPER=~/miniconda3/envs/py2/bin/svtyper-sso
SCRIPTS=~/app/esv_pipe/scripts
SURVIVOR=~/SURVIVOR/Debug/SURVIVOR
EXTRACT_HAIR=~/app/extractHairs/build/ExtractHAIRs
SPECHAP=~/app/SpecHap/build/SpecHap
ESplitReads_BwaMem=~/app/lumpy-sv/scripts/extractSplitReads_BwaMem
DELLY=~/app/delly/delly
PYTHON3=~/miniconda3/envs/py3/bin/python
PYTHON2=~/miniconda3/envs/py2/bin/python2
BGZIP=~/app/htslib/bin/bgzip
TABIX=~/app/htslib/bin/tabix
#GRIDSS=/home/grads/gzpan2/apps/miniconda3/envs/cityu2/share/gridss-2.8.0-0/gridss.jar
bam=$1
ref=$2
out_dir=$3
threads=$4
sample=$6
snp_vcf=$5
bam_filename="$(basename -- $bam)"
if [ ! -d $out_dir ]; then
  mkdir $out_dir
fi
if [ ! -d $out_dir/svaba ]; then
  mkdir $out_dir/svaba
fi
if [ ! -d $out_dir/manta ]; then
  mkdir $out_dir/manta
fi
if [ ! -d $out_dir/lumpy ]; then
  mkdir $out_dir/lumpy
fi
# if [ ! -d $out_dir/gridss ]; then
#   mkdir $out_dir/gridss
# fi
if [ ! -d $out_dir/delly ]; then
  mkdir $out_dir/delly
fi
# if [ ! -f "$bam.bai" ]; then
#   $SAMTOOLS index $bam -@ $threads
# fi
# # svaba
$SVABA run -t $bam -G $ref -a $out_dir/svaba/svaba --read-tracking --germline -p $threads
cp $out_dir/svaba/svaba.svaba.sv.vcf  $out_dir/svaba/svaba.svtyper.sv.vcf
$PYTHON3 $SCRIPTS/adjust_svtyper_genotypes.py $out_dir/svaba/svaba.svtyper.sv.vcf > $out_dir/svaba/svaba.adjusted.vcf
$PYTHON2 $SCRIPTS/svaba_ano.py $out_dir/svaba/svaba.adjusted.vcf > $out_dir/svaba/svaba.adjusted2.vcf
# manta
$CONFIGMANTA --bam $bam --referenceFasta $ref --runDir $out_dir/manta --generateEvidenceBam
$out_dir/manta/runWorkflow.py -m local -j $threads -g 150
gunzip $out_dir/manta/results/variants/diploidSV.vcf.gz
cp $out_dir/manta/results/variants/diploidSV.vcf  $out_dir/manta/manta.svtyper.vcf
time $PYTHON3 $SCRIPTS/parse.py --manta -v $out_dir/manta/manta.svtyper.vcf -b $out_dir/manta/results/evidence/evidence_0.$bam_filename -o $out_dir/manta/manta.evidence.vcf
$PYTHON3 $SCRIPTS/adjust_svtyper_genotypes.py $out_dir/manta/manta.evidence.vcf > $out_dir/manta/manta.adjusted.vcf
$PYTHON3 $SCRIPTS/rm_cross.py -v $out_dir/manta/manta.adjusted.vcf -o $out_dir/manta/manta.adjusted2.vcf -f $ref
# lumpy
$SAMTOOLS view -uF 0x0002 $bam | $SAMTOOLS view -uF 0x100 - | $SAMTOOLS view -uF 0x0004 - | $SAMTOOLS view -uF 0x0008 - | $SAMTOOLS view -bF 0x0400 - | $SAMTOOLS sort - -o $out_dir/lumpy/lumpy.discordant.sort.bam
$SAMTOOLS view -h $bam | $ESplitReads_BwaMem -i stdin | $SAMTOOLS view -Sb - | $SAMTOOLS sort - -o $out_dir/lumpy/lumpy.sr.sort.bam
$LUMPY_EXPRESS -B $bam -S $out_dir/lumpy/lumpy.sr.sort.bam -D $out_dir/lumpy/lumpy.discordant.sort.bam -o $out_dir/lumpy/lumpy.vcf
$PYTHON3 $SCRIPTS/parse.py --lumpy -v $out_dir/lumpy/lumpy.vcf -o $out_dir/lumpy/lumpy.evidence.vcf
$SVTYPER -B $bam -i $out_dir/lumpy/lumpy.evidence.vcf --core $threads -o $out_dir/lumpy/lumpy.svtyper.vcf
$PYTHON3 $SCRIPTS/adjust_svtyper_genotypes.py $out_dir/lumpy/lumpy.svtyper.vcf > $out_dir/lumpy/lumpy.adj.vcf
$PYTHON3 $SCRIPTS/parse2.py -v $out_dir/lumpy/lumpy.adj.vcf --lumpy -o $out_dir/lumpy/lumpy.adjusted.vcf #fix _2 have no reads error
$PYTHON3 $SCRIPTS/rm_cross.py -v $out_dir/lumpy/lumpy.adjusted.vcf -o $out_dir/lumpy/lumpy.adjusted2.vcf -f $ref
# trans to BND format 
#$PYTHON3 $SCRIPTS/trans_to_BND_format.py -v $out_dir/lumpy/lumpy.adjusted.vcf -f $ref -o $out_dir/lumpy/lumpy.adjusted.BND.vcf


#delly
$DELLY call -g $ref -o $out_dir/delly/delly.bcf  $bam --dump $out_dir/delly/delly.dump.gz
$BCFTOOLS view $out_dir/delly/delly.bcf > $out_dir/delly/delly.vcf
cp $out_dir/delly/delly.vcf  $out_dir/delly/delly.svtyper.vcf
gunzip $out_dir/delly/delly.dump.gz
$BCFTOOLS view -f 'PASS' $out_dir/delly/delly.svtyper.vcf -o $out_dir/delly/delly.pass.vcf
$PYTHON3 $SCRIPTS/pdelly.py -v $out_dir/delly/delly.pass.vcf -r $ref -o $out_dir/delly/delly.evidence.vcf -d $out_dir/delly/delly.dump
$PYTHON3 $SCRIPTS/adjust_svtyper_genotypes.py $out_dir/delly/delly.evidence.vcf > $out_dir/delly/delly.adjusted.vcf
$PYTHON3 $SCRIPTS/rm_cross.py -v $out_dir/delly/delly.adjusted.vcf -o $out_dir/delly/delly.adjusted2.vcf -f $ref
# trans to BND format
#$PYTHON3 $SCRIPTS/trans_to_BND_format.py -v $out_dir/delly/delly.adjusted.vcf -f $ref -o $out_dir/delly/delly.adjusted.BND.vcf
# generate input for survivor
if [ -f "$out_dir/sur.input" ]; then
	rm $out_dir/sur.input
fi
touch $out_dir/sur.input
echo "$out_dir/manta/manta.adjusted2.vcf" >> $out_dir/sur.input
echo "$out_dir/svaba/svaba.adjusted2.vcf" >> $out_dir/sur.input
echo "$out_dir/lumpy/lumpy.adjusted2.vcf" >> $out_dir/sur.input
echo "$out_dir/delly/delly.adjusted2.vcf" >> $out_dir/sur.input

#sur
$SURVIVOR merge $out_dir/sur.input 200 2 1 0 0 10 $out_dir/survivor.output.vcf
$BCFTOOLS sort $out_dir/survivor.output.vcf -o $out_dir/survivor.sort.vcf
$PYTHON2 $SCRIPTS/combine_combined.py $out_dir/survivor.sort.vcf $sample $out_dir/sur.input $SCRIPTS/all.phred.txt > $out_dir/combined.genotyped.vcf
$BGZIP -f $out_dir/combined.genotyped.vcf
$BCFTOOLS sort $out_dir/combined.genotyped.vcf.gz > $out_dir/combined.genotyped.sort.vcf
#$BCFTOOLS sort $out_dir/combined.genotyped.vcf.gz -Oz > $out_dir/combined.genotyped.sort.vcf.gz
#$TABIX -f $out_dir/combined.genotyped.sort.vcf.gz
#$BCFTOOLS concat -a $out_dir/combined.genotyped.sort.vcf.gz $snp_vcf -Oz -o $out_dir/all.vcf.gz
#$TABIX $out_dir/all.vcf.gz
#$EXTRACT_HAIR --bam $bam --vcf $out_dir/all.vcf.gz --out $out_dir/ext.lst --breakends 1 --mate_at_same 1 --support_read_tag READNAMES --contigs chr1,chr2,chr3,chr4,chr5,chr6,chr7,chr8,chr9,chr10,chr11,chr12,chr13,chr14,chr15,chr16,chr17,chr18,chr19,chr20,chr21,chr22,chrX,chrY
#sort -n -k3 $out_dir/ext.lst > $out_dir/ext.sorted.lst
#$SPECHAP -v $out_dir/all.vcf.gz -f $out_dir/ext.sorted.lst -o $out_dir/spec.vcf -p ngs
