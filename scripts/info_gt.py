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
        if line.startswith("##"):
            out_vcf.write(line)
            continue
        else:
            if not gt_f:
                out_vcf.write('##FORMAT=<ID=READNAMES,Number=G,Type=String,Description="Support reads name">\n')
                gt_f = True
            if line.startswith("#CHROM"):
                out_vcf.write(line)
                continue
            tmp = line.strip().split("\t")
            lls = tmp[7].split(";")
            no_svlen = False
            if "SVLEN" not in tmp[7]:
                no_svlen = True
            if "READNAMES" in tmp[7]:
                for i in range(len(lls)-1,-1,-1):
                    if no_svlen and lls[i].startswith("END"):
                        end = int(lls[i].split("=")[1])
                        lls[i] = lls[i] + ";SVLEN=" + str(end - int(tmp[1]))
                    if "READNAMES" in lls[i]:
                        tmp[8] = tmp[8] + ":READNAMES"
                        tmp[9] = tmp[9] +":"+lls[i].replace("READNAMES=","")
                        del lls[i]
            sr_pe_pr_idxs = []
            t8_split = tmp[8].split(":")
            t9_split = tmp[9].split(":")
            info_add_str = ""
            for idx,item in enumerate(t8_split):
                if item in ["SR","PE","PR"]:
                    sr_pe_pr_idxs.append(idx)
            for idx,item in enumerate(t9_split):
                if idx in sr_pe_pr_idxs:
                    if "," in t9_split[idx]:
                        info_add_str = info_add_str +";" + t8_split[idx] + "=" +  t9_split[idx].split(",")[-1]
                    else:
                        info_add_str = info_add_str +";" + t8_split[idx] + "=" +  t9_split[idx]
            tmp[7] = ";".join(lls)
            tmp[7] = tmp[7] + ";"+ info_add_str
            if "BND" not in tmp[2]:
                out_vcf.write("\t".join(tmp)+"\n")
                continue
            out_vcf.write("\t".join(tmp)+"\n")

if __name__ == '__main__':
    main()
