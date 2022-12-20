#!/bin/bash
#change tools to your path, notice that, you should install SURVIVOR from https://github.com/panguangze/SURVIVOR.git
#set -x
SVABA=/home/panguangze/miniconda3/envs/apps/bin/svaba
CONFIGMANTA=/home/panguangze/miniconda3/envs/apps/bin/configManta.py
SAMTOOLS=~/apps/usr/local/bin/samtools
BCFTOOLS=~/apps/usr/local/bin/bcftools
LUMPY_EXPRESS=/home/panguangze/miniconda3/envs/apps/bin/lumpyexpress
SVTYPER=/home/panguangze/miniconda3/envs/apps/bin/svtyper
SCRIPTS=/home/panguangze/tmp_file/esv_pipe/scripts
SURVIVOR=~/tmp_file/SURVIVOR/Debug/SURVIVOR
EXTRACT_HAIR=ExtractHAIRs
SPECHAP=SpecHap
ESplitReads_BwaMem=/home/panguangze/miniconda3/envs/apps/bin/extractSplitReads_BwaMem
DELLY=/home/panguangze/tmp_file/delly/src/delly
PYTHON3=/home/panguangze/miniconda3/envs/apps/bin/python
PYTHON2=python2
BGZIP=bgzip
TABIX=tabix
#GRIDSS=/home/grads/gzpan2/apps/miniconda3/envs/cityu2/share/gridss-2.8.0-0/gridss.jar
bam=$1
ref=$2
out_dir=$3
threads=$4
sampleName=$5
# snp_vcf=$5
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
#if [ ! -f $out_dir/svaba/svaba.svaba.sv.vcf ]; then
#	$SVABA run -t $bam -G $ref -a $out_dir/svaba/svaba --read-tracking --germline -p $threads
#	$PYTHON3 $SCRIPTS/adjust_svtyper_genotypes.py $out_dir/svaba/svaba.svaba.sv.vcf > $out_dir/svaba/svaba.svtyper.sv.vcf
#	$PYTHON2 $SCRIPTS/svaba_ano.py $out_dir/svaba/svaba.svtyper.sv.vcf > $out_dir/svaba/svaba.adjusted.vcf
#fi
#clean
#rm $out_dir/svaba/svaba.bps.txt.gz
#rm $out_dir/svaba/svaba.contigs.bam
#rm $out_dir/svaba/svaba.alignments.txt.gz
#rm $out_dir/svaba/svaba.svaba.unfiltered.indel.vcf
#rm $out_dir/svaba.discordant.txt.gz
#bgzip $out_dir/svaba/svaba.svaba.indel.vcf
#rm $out_dir/svaba/svaba.log
# manta
if [ ! -f $out_dir/manta/manta.svtyper.vcf ]; then
	$CONFIGMANTA --bam $bam --referenceFasta $ref --runDir $out_dir/manta --generateEvidenceBam
	$out_dir/manta/runWorkflow.py -m local -j $threads -g 150
	gunzip $out_dir/manta/results/variants/diploidSV.vcf.gz
	cp $out_dir/manta/results/variants/diploidSV.vcf  $out_dir/manta/manta.svtyper.vcf
	#time $PYTHON3 $SCRIPTS/parse.py --manta -v $out_dir/manta/manta.svtyper.vcf -b $out_dir/manta/results/evidence/evidence_0.$bam_filename -o $out_dir/manta/manta.evidence.vcf
fi
$PYTHON3 $SCRIPTS/adjust_svtyper_genotypes.py $out_dir/manta/manta.svtyper.vcf > $out_dir/manta/manta.adjusted.vcf

#clean
rm $out_dir/manta/workspace -rf

# $PYTHON3 $SCRIPTS/rm_cross.py -v $out_dir/manta/manta.adjusted.vcf -o $out_dir/manta/manta.adjusted2.vcf -f $ref
# lumpy
if [ ! -f $out_dir/lumpy/lumpy.vcf ]; then
	if [ ! -f $out_dir/lumpy/lumpy.discordant.sort.bam ]; then
		$SAMTOOLS view -uF 0x0002 $bam | $SAMTOOLS view -uF 0x100 - | $SAMTOOLS view -uF 0x0004 - | $SAMTOOLS view -uF 0x0008 - | $SAMTOOLS view -bF 0x0400 - | $SAMTOOLS sort - -o $out_dir/lumpy/lumpy.discordant.sort.bam
	fi
	if [ ! -f $out_dir/lumpy/lumpy.sr.sort.bam ]; then
		$SAMTOOLS view -h $bam | $PYTHON2 $ESplitReads_BwaMem -i stdin | $SAMTOOLS view -Sb - | $SAMTOOLS sort - -o $out_dir/lumpy/lumpy.sr.sort.bam
	fi
	$LUMPY_EXPRESS -B $bam -S $out_dir/lumpy/lumpy.sr.sort.bam -D $out_dir/lumpy/lumpy.discordant.sort.bam -o $out_dir/lumpy/lumpy.vcf
else
	rm $out_dir/lumpy/lumpy.discordant.sort.bam
	rm $out_dir/lumpy/lumpy.sr.sort.bam
fi
$PYTHON3 $SCRIPTS/parse.py --lumpy -v $out_dir/lumpy/lumpy.vcf -o $out_dir/lumpy/lumpy.noevidence.vcf
$BCFTOOLS filter -i "FORMAT/SU < 5" $out_dir/lumpy/lumpy.noevidence.vcf -o $out_dir/lumpy/lumpy.su.vcf
#$SVTYPER -B $bam -i $out_dir/lumpy/lumpy.su.vcf -o $out_dir/lumpy/lumpy.adjusted.vcf
#$PYTHON3 $SCRIPTS/parse2.py -v $out_dir/lumpy/lumpy.adj.vcf --lumpy -o $out_dir/lumpy/lumpy.adjusted.vcf #fix _2 have no reads error
# $PYTHON3 $SCRIPTS/rm_cross.py -v $out_dir/lumpy/lumpy.adjusted.vcf -o $out_dir/lumpy/lumpy.adjusted2.vcf -f $ref
# trans to BND format 
#$PYTHON3 $SCRIPTS/trans_to_BND_format.py -v $out_dir/lumpy/lumpy.adjusted.vcf -f $ref -o $out_dir/lumpy/lumpy.adjusted.BND.vcf


#delly
if [ ! -f $out_dir/delly/delly.vcf ]; then
	$DELLY call -g $ref -o $out_dir/delly/delly.bcf  $bam --dump $out_dir/delly/delly.dump.gz
	$BCFTOOLS view $out_dir/delly/delly.bcf > $out_dir/delly/delly.vcf
	cp $out_dir/delly/delly.vcf  $out_dir/delly/delly.svtyper.vcf
	gunzip $out_dir/delly/delly.dump.gz
fi
echo "done"
#$BCFTOOLS view -f 'PASS' $out_dir/delly/delly.svtyper.vcf -o $out_dir/delly/delly.pass.vcf
#$PYTHON3 $SCRIPTS/pdelly.py -v $out_dir/delly/delly.pass.vcf -r $ref -o $out_dir/delly/delly.evidence.vcf -d $out_dir/delly/delly.dump
#$PYTHON3 $SCRIPTS/adjust_svtyper_genotypes.py $out_dir/delly/delly.evidence.vcf > $out_dir/delly/delly.adjusted.vcf
# $PYTHON3 $SCRIPTS/rm_cross.py -v $out_dir/delly/delly.adjusted.vcf -o $out_dir/delly/delly.adjusted2.vcf -f $ref
# trans to BND format
#$PYTHON3 $SCRIPTS/trans_to_BND_format.py -v $out_dir/delly/delly.adjusted.vcf -f $ref -o $out_dir/delly/delly.adjusted.BND.vcf
# generate input for survivor

#$BCFTOOLS view -f PASS -i "FORMAT/RV>=10" $out_dir/delly/delly.adjusted.vcf $out_dir/delly/delly.sr10.vcf
#$BCFTOOLS view -i "FORMAT/SR + FORMAT/PE >= 10" $out_dir/lumpy/lumpy.adjusted.vcf -o $out_dir/lumpy/lumpy.sr10.vcf
#$BCFTOOLS view -i "FORMAT/FT='PASS' && FORMAT/SR[0:1]>=10" $out_dir/manta/manta.adjusted.vcf -o $out_dir/manta/manta.sr10.vcf
#$BCFTOOLS view -i "FORMAT/SR>=10" $out_dir/svaba/svaba.adjusted.vcf -o $out_dir/svaba/svaba.sr10.vcf


#if [ -f "$out_dir/sur.input" ]; then
#	rm $out_dir/sur.input
#fi
#touch $out_dir/sur.input
#echo "$out_dir/delly/delly.sr10.vcf" >> $out_dir/sur.input
#echo "$out_dir/lumpy/lumpy.sr10.vcf" >> $out_dir/sur.input
#echo "$out_dir/manta/manta.sr10.vcf" >> $out_dir/sur.input
#echo "$out_dir/svaba/svaba.sr10.vcf" >> $out_dir/sur.input

#sur
#$SURVIVOR merge $out_dir/sur.input 100 2 1 1 1 10 $out_dir/survivor.sr10.vcf
#$BCFTOOLS sort $out_dir/survivor.sr10.vcf -o $out_dir/survivor.sr10.sort.vcf
#$PYTHON2 $SCRIPTS/combine_combined.py $out_dir/survivor.sr10.sort.vcf $sampleName $out_dir/sur.input $SCRIPTS/all.phred.txt > $out_dir/combined.sr10.vcf
#$BGZIP -f $out_dir/combined.sr10.vcf
#$BCFTOOLS sort $out_dir/combined.sr10.vcf.gz > $out_dir/combined.sr10.sort.vcf
#$BCFTOOLS sort $out_dir/combined.genotyped.vcf.gz -Oz > $out_dir/combined.genotyped.sort.vcf.gz
#$TABIX -f $out_dir/combined.genotyped.sort.vcf.gz
#$BCFTOOLS concat -a $out_dir/combined.genotyped.sort.vcf.gz $snp_vcf -Oz -o $out_dir/all.vcf.gz
#$TABIX $out_dir/all.vcf.gz
#$EXTRACT_HAIR --bam $bam --vcf $out_dir/all.vcf.gz --out $out_dir/ext.lst --breakends 1 --mate_at_same 1 --support_read_tag READNAMES --contigs chr1,chr2,chr3,chr4,chr5,chr6,chr7,chr8,chr9,chr10,chr11,chr12,chr13,chr14,chr15,chr16,chr17,chr18,chr19,chr20,chr21,chr22,chrX,chrY
#sort -n -k3 $out_dir/ext.lst > $out_dir/ext.sorted.lst
#$SPECHAP -v $out_dir/all.vcf.gz -f $out_dir/ext.sorted.lst -o $out_dir/spec.vcf -p ngs
