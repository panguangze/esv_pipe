import argparse
from math import fabs
import re
def main():
    parser = argparse.ArgumentParser("parse")
    parser.add_argument('-v', required=True)
    parser.add_argument('-o', required=True)
    args = parser.parse_args()
    in_vcf = open(args.v)
    out_vcf = open(args.o,"w")
    gt_f=False
    for line in in_vcf.readlines():
        if line.startswith("#"):
            out_vcf.write(line)
            continue
        else:
            if not gt_f:
                out_vcf.write('##FORMAT=<ID=READNAMES,Number=G,Type=String,Description="Support reads name">\n')
                gt_f = True
            tmp = line.strip().split("\t")
            lls = tmp[7].split(";")
            if "READNAMES" in tmp[7]:
                for i in range(0,len(lls) - 1):
                    if "READNAMES" in lls[i]:
                        tmp[8] = tmp[8] + ":READNAMES" 
                        tmp[9] = tmp[9] +":"+lls[i].replace("READNAMES=","")
                        del lls[i]
            tmp[7] = ";".join(lls)
            if "BND" not in tmp[2]:
                out_vcf.write("\t".join(tmp)+"\n")
                continue
            out_vcf.write("\t".join(tmp)+"\n")

if __name__ == '__main__':
    main()
