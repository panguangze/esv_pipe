#!/bin/bash
#change tools to your path, for order file check order.txt
#EXTRACT_HAIR: https://github.com/panguangze/extractHairs.git no_blast_v branch
#spechap: https://github.com/panguangze/SpecHap.git dev branch
#PEDHAP: https://github.com/panguangze/pedHapCpp.git main branch
#These tools installed with cmake
cbam=$1
fbam=$2
mbam=$3
out_dir=$4
ref=$5
vcf=$6
order=$7
EXTRACT_HAIR=ExtractHAIRs
SPECHAP=SpecHap
PEDHAP=pedHap
#bgzip $vcf
#tabix $vcf.gz
rm $out_dir/homo_recom.txt
mkdir -p $out_dir
if [ ! -f "$out_dir/c.ext.sorted.lst" ]; then
        $EXTRACT_HAIR --bam $cbam --vcf $vcf --out $out_dir/c.ext.lst --breakends 1 --ep 1 --mate_at_same 1 --support_read_tag READNAMES --idx 0 --contigs chr1,chr2,chr3,chr4,chr5,chr6,chr7,chr8,chr9,chr10,chr11,chr12,chr13,chr14,chr15,chr16,chr17,chr18,chr19,chr20,chr21,chr22,chrX,chrY
        sort -n -k3 $out_dir/c.ext.lst > $out_dir/c.ext.sorted.lst
fi
if [ ! -f "$out_dir/f.ext.sorted.lst" ]; then
        $EXTRACT_HAIR --bam $fbam --vcf $vcf --out $out_dir/f.ext.lst --breakends 1 --ep 1 --mate_at_same 1 --support_read_tag READNAMES --idx 1 --contigs chr1,chr2,chr3,chr4,chr5,chr6,chr7,chr8,chr9,chr10,chr11,chr12,chr13,chr14,chr15,chr16,chr17,chr18,chr19,chr20,chr21,chr22,chrX,chrY
        sort -n -k3 $out_dir/f.ext.lst > $out_dir/f.ext.sorted.lst
fi
if [ ! -f "$out_dir/m.ext.sorted.lst" ]; then
        $EXTRACT_HAIR --bam $mbam --vcf $vcf --out $out_dir/m.ext.lst --breakends 1 --ep 1 --mate_at_same 1 --support_read_tag READNAMES --idx 2 --contigs chr1,chr2,chr3,chr4,chr5,chr6,chr7,chr8,chr9,chr10,chr11,chr12,chr13,chr14,chr15,chr16,chr17,chr18,chr19,chr20,chr21,chr22,chrX,chrY
        sort -n -k3 $out_dir/m.ext.lst > $out_dir/m.ext.sorted.lst
fi
tabix $vcf


if [ ! -f "$out_dir/c.spec.ngs.vcf.gz.tbi" ]; then
        $SPECHAP -v $vcf -f $out_dir/c.ext.sorted.lst -o $out_dir/c.spec.ngs.vcf -p ngs --idx 0 --contigs chr5,chr6,chr15,chr16
        bgzip $out_dir/c.spec.ngs.vcf
        tabix $out_dir/c.spec.ngs.vcf.gz
fi

if [ ! -f "$out_dir/f.spec.ngs.vcf.gz.tbi" ]; then
        $SPECHAP -v $out_dir/c.spec.ngs.vcf.gz -f $out_dir/f.ext.sorted.lst -o $out_dir/f.spec.ngs.vcf -p ngs --idx 1 --contigs chr5,chr6,chr15,chr16
        bgzip $out_dir/f.spec.ngs.vcf
        tabix $out_dir/f.spec.ngs.vcf.gz
fi

if [ ! -f "$out_dir/m.spec.ngs.vcf.gz.tbi" ]; then
        $SPECHAP -v $out_dir/f.spec.ngs.vcf.gz -f $out_dir/m.ext.sorted.lst -o $out_dir/m.spec.ngs.vcf -p ngs --idx 2 --contigs chr5,chr6,chr15,chr16,
        bgzip $out_dir/m.spec.ngs.vcf
        tabix $out_dir/m.spec.ngs.vcf.gz
fi
$PEDHAP --vcf $out_dir/m.spec.ngs.vcf.gz --ped $order --out $out_dir/trio.phased.vcf --homo_recom $out_dir/homo_recom.txt --debug --seg_dup /home/gzpan2/app/pedHapCpp/scripts/chm13v2.0_SD.bed --simple_repeat /home/gzpan2/app/pedHapCpp/scripts/chm13.simpleRepeat.50.bed --contigs chr5,chr6,chr15,chr16
python /home/gzpan2/app/pedHapCpp/scripts/parse_recom.py $out_dir/homo_recom.txt $out_dir/recom.parse.txt $out_dir/homo_recom.bed