#set -x
SAMTOOLS=~/apps/usr/local/bin/samtools
BCFTOOLS=~/apps/usr/local/bin/bcftools
SCRIPTS=~/tmp_file/esv_pipe/scripts
SURVIVOR=~/tmp_file/SURVIVOR/Debug/SURVIVOR
EXTRACT_HAIR=ExtractHAIRs
PYTHON3=/home/panguangze/miniconda3/envs/apps/bin/python
PYTHON2=python2
BGZIP=~/apps/usr/local/bin/bgzip
TABIX=~/apps/usr/local/bin/tabix

out_dir=$1
sample=$2
threshold=$3
support=$4
mkdir $out_dir/dysgu

#$PYTHON3 $SCRIPTS/plumpy.py -v $out_dir/lumpy/lumpy.adjusted.vcf --lumpy -o $out_dir/lumpy/lumpy.adjusted2.vcf

#$PYTHON3 $SCRIPTS/pdelly.py -v $out_dir/delly/delly.vcf -r /scratch/project/cs_shuaicli/reference/t2t_ref/chm13v2.0.fa -o $out_dir/delly/delly.adjusted.vcf -d $out_dir/delly/delly.dump
#$PYTHON3 $SCRIPTS/adjust_svtyper_genotypes.py $out_dir/delly/delly.evidence.vcf > $out_dir/delly/delly.adjusted.vcf

#$BCFTOOLS view -f PASS -i "(INFO/PE + INFO/SR)>=$threshold" $out_dir/delly/delly.adjusted.vcf -o $out_dir/delly/delly.sr_$threshold.vcf
#$BCFTOOLS view -i "(FORMAT/SR + FORMAT/PE) >= $threshold" $out_dir/lumpy/lumpy.adjusted2.vcf -o $out_dir/lumpy/lumpy.sr_$threshold.vcf
#$BCFTOOLS view -f PASS -i "(FORMAT/SR[0:1] + FORMAT/PR[0:1])>=$threshold" $out_dir/manta/manta.adjusted.noreads.vcf -o $out_dir/manta/manta.sr_$threshold.vcf
#$BCFTOOLS view -i "FORMAT/SR>=10" $out_dir/svaba/svaba.adjusted2.vcf -o $out_dir/svaba/svaba.sr_$threshold.vcf
#$BCFTOOLS view -f PASS -i "INFO/SC>=$threshold || INFO/PE>=$threshold" ../dysgu_vcf/$sample.dysgu.vcf -o $out_dir/dysgu/dysgu.sr_$threshold.vcf

$PYTHON2 $SCRIPTS/svaba_ano.py $out_dir/svaba/svaba.adjusted.vcf > $out_dir/svaba/svaba.adjusted2.vcf

$BCFTOOLS view -f PASS -i "(INFO/PE + INFO/SR)>=$threshold" $out_dir/delly/delly.adjusted.vcf -o $out_dir/delly/delly.sr_$threshold.vcf
$BCFTOOLS view -i "FORMAT/SU>= $threshold" $out_dir/lumpy/lumpy.adjusted2.vcf -o $out_dir/lumpy/lumpy.sr_$threshold.vcf
$BCFTOOLS view -f PASS -i "(FORMAT/SR[0:1] + FORMAT/PR[0:1])>=$threshold" $out_dir/manta/manta.adjusted.noreads.vcf -o $out_dir/manta/manta.sr_$threshold.vcf
#$BCFTOOLS view -i "FORMAT/SR>=$threshold" $out_dir/svaba/svaba.adjusted2.vcf -o $out_dir/svaba/svaba.sr_$threshold.vcf
$BCFTOOLS view -f PASS -i "(INFO/SC + INFO/PE)>=$threshold" ../dysgu_vcf/$sample.dysgu.vcf -o $out_dir/dysgu/dysgu.sr_$threshold.vcf
/home/panguangze/miniconda3/envs/apps/bin/convertInversion.py $SAMTOOLS ~/t2t_ref/chm13v2.0.fa $out_dir/manta/manta.sr_$threshold.vcf > $out_dir/manta/manta.sr_$threshold.inv.vcf

if [ -f "$out_dir/sur.sr_$threshold.input" ]; then
	        rm $out_dir/sur.sr_$threshold.input
	fi
$PYTHON3 $SCRIPTS/info_gt.py -v $out_dir/delly/delly.sr_$threshold.vcf -o $out_dir/delly/delly.sr_$threshold.gt.vcf
$PYTHON3 $SCRIPTS/info_gt.py -v $out_dir/manta/manta.sr_$threshold.inv.vcf -o $out_dir/manta/manta.sr_$threshold.gt.vcf
$PYTHON3 $SCRIPTS/info_gt.py -v $out_dir/lumpy/lumpy.sr_$threshold.vcf -o $out_dir/lumpy/lumpy.sr_$threshold.gt.vcf
$PYTHON3 $SCRIPTS/info_gt.py -v $out_dir/dysgu/dysgu.sr_$threshold.vcf -o $out_dir/dysgu/dysgu.sr_$threshold.gt.vcf
#$PYTHON3 $SCRIPTS/info_gt.py -v $out_dir/svaba/svaba.sr_$threshold.vcf -o $out_dir/svaba/svaba.sr_$threshold.gt.vcf
$BCFTOOLS filter -e 'INFO/SVLEN>5000000 || INFO/SVLEN< -5000000 || (INFO/SVLEN<50 && INFO/SVLEN>0)|| (INFO/SVLEN> -50 && INFO/SVLEN<0)' $out_dir/delly/delly.sr_$threshold.gt.vcf > $out_dir/delly/delly.sr_$threshold.gt.len.vcf
$BCFTOOLS filter -e 'INFO/SVLEN>5000000 || INFO/SVLEN< -5000000 || (INFO/SVLEN<50 && INFO/SVLEN>0)|| (INFO/SVLEN> -50 && INFO/SVLEN<0)' $out_dir/manta/manta.sr_$threshold.gt.vcf > $out_dir/manta/manta.sr_$threshold.gt.len.vcf
#$BCFTOOLS filter -e 'INFO/SVLEN>5000000 || INFO/SVLEN< -5000000 || (INFO/SVLEN<50 && INFO/SVLEN>0)|| (INFO/SVLEN> -50 && INFO/SVLEN<0)' $out_dir/svaba/svaba.sr_$threshold.gt.vcf > $out_dir/svaba/svaba.sr_$threshold.gt.len.vcf
cp $out_dir/svaba/svaba.sr_$threshold.gt.vcf $out_dir/svaba/svaba.sr_$threshold.gt.len.vcf
$BCFTOOLS filter -e 'INFO/SVLEN>5000000 || INFO/SVLEN< -5000000 || (INFO/SVLEN<50 && INFO/SVLEN>0)|| (INFO/SVLEN> -50 && INFO/SVLEN<0)' $out_dir/lumpy/lumpy.sr_$threshold.gt.vcf > $out_dir/lumpy/lumpy.sr_$threshold.gt.len.vcf
$BCFTOOLS filter -e 'INFO/SVLEN>5000000 || INFO/SVLEN< -5000000 || (INFO/SVLEN<50 && INFO/SVLEN>0)|| (INFO/SVLEN> -50 && INFO/SVLEN<0)' $out_dir/dysgu/dysgu.sr_$threshold.gt.vcf > $out_dir/dysgu/dysgu.sr_$threshold.gt.len.vcf
touch $out_dir/sur.sr_$threshold.input
echo "$out_dir/dysgu/dysgu.sr_$threshold.gt.len.vcf" >> $out_dir/sur.sr_$threshold.input
echo "$out_dir/delly/delly.sr_$threshold.gt.len.vcf" >> $out_dir/sur.sr_$threshold.input
echo "$out_dir/lumpy/lumpy.sr_$threshold.gt.len.vcf" >> $out_dir/sur.sr_$threshold.input
echo "$out_dir/manta/manta.sr_$threshold.gt.len.vcf" >> $out_dir/sur.sr_$threshold.input
#echo "$out_dir/svaba/svaba.sr_$threshold.gt.len.vcf" >> $out_dir/sur.sr_$threshold.input
#echo "$out_dir/svaba/svaba.sr_$threshold.vcf" >> $out_dir/sur.sr_$threshold.input

$SURVIVOR merge $out_dir/sur.sr_$threshold.input 100 $support 1 0 1 50 $out_dir/survivor.sr_$threshold.vcf
$BCFTOOLS sort $out_dir/survivor.sr_$threshold.vcf -o $out_dir/survivor.sr_$threshold.sort.vcf
$PYTHON2 $SCRIPTS/combine_combined.py $out_dir/survivor.sr_$threshold.sort.vcf $sample $out_dir/sur.sr_$threshold.input $SCRIPTS/all.phred.txt > $out_dir/combined.sr_$threshold.vcf
$BGZIP -f $out_dir/combined.sr_$threshold.vcf
$BCFTOOLS sort $out_dir/combined.sr_$threshold.vcf.gz > $out_dir/combined.sr_$threshold.sort.vcf
