#!/bin/bash
#change tools to your path
csv=$1
fsv=$2
msv=$3
snp=$4
out_dir=$5
if [ -f "$out_dir/sur.input" ]; then
	rm $out_dir/sur.input
fi
touch $out_dir/sur.input
echo $csv >> $out_dir/sur.input
echo $fsv >> $out_dir/sur.input
echo $msv >> $out_dir/sur.input

~/SURVIVOR/Debug/SURVIVOR merge $out_dir/sur.input 200 1 1 0 0 10 $out_dir/trio.merged.sv.vcf
bcftools sort $out_dir/trio.merged.sv.vcf -o $out_dir/trio.merged.sv.sorted.vcf
bgzip $out_dir/trio.merged.sv.sorted.vcf
tabix $out_dir/trio.merged.sv.sorted.vcf.gz
~/app/bcftools/bin/bcftools concat -a $snp $out_dir/trio.merged.sv.sorted.vcf.gz -Oz -o $out_dir/all.sv.snp.vcf.gz
tabix $out_dir/all.sv.snp.vcf.gz