import argparse
import re
from pyfaidx import Fasta

import re
def main():
    parser = argparse.ArgumentParser("bnd convert")

    parser.add_argument('-v', help="input sv file", required=True, dest='vcf_file')
    parser.add_argument('-o', help="out put sv file", required=True, dest='out_file')
    parser.add_argument('-f', help="ref for correct REF", required=True, dest="ref")


    args = parser.parse_args()
    fa = Fasta(args.ref)
    flag = True
    out_put = open(args.out_file, 'w')
    for line in open(args.vcf_file):
        if line.startswith('#CHR'):
            out_put.write('##INFO=<ID=dup_num,Number=1,Type=Integer,Description="Length of the SV">\n')
            out_put.write(line)
            continue
        if line.startswith('#'):
            out_put.write(line)
            continue
        record = line.split('\t')
        ID = record[2]
        # print(record)
        record[8] = "GT"
        if "SNP" in ID:
            out_put.write('\t'.join(record))
            continue
        #
        formats = re.split(';|=', record[7])
        # i = formats.index('SVLEN')
        # sv_len = abs(int(formats[i+1]))
        if "]" in record[4] or "[" in record[4]:
            if (record[0] != re.split(r'[\]\[\:]',record[4])[1]) and not (record[0] in ["chrX","chrY"] and re.split(r'[\]\[\:]',record[4])[1] in ["chrX","chrY"]):
                continue
        out_put.write('\t'.join(record))
            # out_put.write('\t'.join(record))
        # record[2] = ID +":1"
        # out_put.write('\t'.join(record))
        # record[2] = ID + ":2"
        # formats = re.split(';|=', record[7])
        # #
        # try:
        #     i = formats.index('DEL')
        #     len = abs(int(formats[i+2]))
        #     record[1] = str(int(record[1]) + len + 1)
        #     out_put.write('\t'.join(record))
        # except:
        #     pass
        # try:
        #     i = formats.index('INS')
        #     # len = abs(int(formats[i+2]))
        #     record[1] = str(int(record[1]) + 1)
        #     out_put.write('\t'.join(record))
        # except:
        #     pass
    out_put.close()

if __name__ == "__main__":
    main()
