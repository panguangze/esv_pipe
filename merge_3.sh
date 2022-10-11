child_sv=$1
p1_sv=$2
p2_sv=$3
snp=$4
out_dir=$5

mkdir -p $out_dir
if [ -f "$out_dir/trio.sr10.input" ]; then
        rm $out_dir/trio.sr10.input
fi
touch $out_dir/trio.sr10.input
echo $child_sv >> $out_dir/trio.sr10.input
echo $p1_sv >> $out_dir/trio.sr10.input
echo $p2_sv >> $out_dir/trio.sr10.input

$SURVIVOR merge $out_dir/trio.sr10.input 100 1 1 1 1 10 $out_dir/trio.sr10.sv.vcf
$BCFTOOLS sort $out_dir/trio.sr10.sv.vcf -Oz -o $out_dir/trio.sr10.sv.sort.vcf.gz
$TABIX $out_dir/trio.sr10.sv.sort.vcf.gz
$BCFTOOLS merge -Oz -0 -o $trio_name.sorted.snp.vcf.gz $csnp $fsnp $msnp
$TABIX $trio_name.merged.snp.vcf.gz
$BCFTOOLS concat -Oz -o $snp $out_dir/trio.sr10.sv.sort.vcf.gz $out_dir/trio.sr10.all.vcf.gz
$out_dir/trio.sr10.all.vcf.gz