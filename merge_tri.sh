set -x
SAMTOOLS=~/apps/usr/local/bin/samtools
BCFTOOLS=~/apps/usr/local/bin/bcftools
SCRIPTS=~/app/esv_pipe/scripts
SURVIVOR=~/tmp_file/SURVIVOR/Debug/SURVIVOR
EXTRACT_HAIR=ExtractHAIRs
PYTHON3=/home/panguangze/miniconda3/envs/apps/bin/python
PYTHON2=python2
BGZIP=~/apps/usr/local/bin/bgzip
TABIX=~/apps/usr/local/bin/tabix
child_sv=$1
p1_sv=$2
p2_sv=$3
snp=$4
out_dir=$5

mkdir -p $out_dir
if [ -f "$out_dir/trio.input" ]; then
        rm $out_dir/trio.input
fi
touch $out_dir/trio.input
echo $child_sv >> $out_dir/trio.input
echo $p1_sv >> $out_dir/trio.input
echo $p2_sv >> $out_dir/trio.input

$SURVIVOR merge $out_dir/trio.input 100 1 1 0 1 50 $out_dir/trio.sv.vcf
$BCFTOOLS view -e "(INFO/SUPP_VEC='001' && FORMAT/DR[2:1]<=10) || (INFO/SUPP_VEC='010' && FORMAT/DR[1:1]<=10) || (INFO/SUPP_VEC='011' && FORMAT/DR[2:1]<=10 && FORMAT/DR[1:1]<=10)" $out_dir/trio.sv.vcf -o $out_dir/trio.vec.sv.vcf
$BCFTOOLS sort $out_dir/trio.vec.sv.vcf -Oz -o $out_dir/trio.sv.sort.vcf.gz
$TABIX $out_dir/trio.sv.sort.vcf.gz
$BCFTOOLS concat --threads 24 -a -Oz $snp $out_dir/trio.sv.sort.vcf.gz -o $out_dir/trio.all.vcf.gz
$TABIX $out_dir/trio.all.vcf.gz
