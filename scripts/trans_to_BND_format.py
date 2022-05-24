import argparse
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
            out_put.write('\t'.join(record))
            continue
        print(record, "3333")

        print(formats, 'fff')
        i = formats.index('END')
        sv_end = abs(int(formats[i+1]))
        c_pos = int(record[1])
        
        record[3] = str(fa[record[0]][c_pos-1:c_pos+2][0])
        if "INV" in record[4]:
            r1 = record[1]
            r2 = str(c_pos + 1)
            r3 = str(sv_end)
            r4 = str(sv_end + 1)

            alt1 = record[3]+"]"+record[0]+":"+r3+"]"
            alt2 = "["+record[0]+":"+r4+"["+record[3]
            alt3 = "N"+"]"+record[0]+":"+r1+"]"
            alt4 = "["+record[0]+":"+r2+"["+"N"
            # 1
            record[1] = r1
            record[2] = ID + "_" + r1+":1"
            record[4] = alt1
            out_put.write('\t'.join(record))
            # 2
            record[1] = r2
            record[2] = ID + "_" + r2+":1"
            record[3] = str(fa[record[0]][c_pos:c_pos+2][0])
            record[4] = alt2
            out_put.write('\t'.join(record))
            # 3
            record[1] = r3
            record[2] = ID + "_" + r1+":2"
            record[3] = str(fa[record[0]][sv_end-1:sv_end+2][0])
            record[4] = alt3
            out_put.write('\t'.join(record))
            # 4
            record[1] = r4
            record[2] = ID + "_" + r2+":2"
            record[3]= str(fa[record[0]][sv_end:sv_end+2][0])
            record[4] = alt4
            out_put.write('\t'.join(record))
        if "DEL" in record[4]:
            r1 = record[1]
            r2 = str(sv_end + 1)
            alt1 = record[3] + "[" + record[0] + ":" + r2+"["
            alt2 = "]" + record[0] + ":" + r1+"]" + "N"
            # 1
            record[1] = r1
            record[2] = ID + "_" + r1+":1"
            record[4] = alt1
            out_put.write('\t'.join(record))
            # 2
            record[1] = r2
            record[2] = ID + "_" + r1+":2"
            record[4] = alt2
            out_put.write('\t'.join(record))
        if "DUP" in record[4]:
            r1 = record[1]
            r2 = str(sv_end)
            alt1 = "]" + record[0] + ":" + r2+"]" + record[3]
            alt2 = "N" + "[" + record[0] + ":" + r1+"["
            # 1
            record[1] = r1
            record[2] = ID + "_" + r1+":1"
            record[4] = alt1
            out_put.write('\t'.join(record))
            # 2
            record[1] = r2
            record[2] = ID + "_" + r1+":2"
            record[4] = alt2
            out_put.write('\t'.join(record))
        if "INS" in record[4]:
            r1 = record[1]
            r2 = str(c_pos + 1)
            alt1 = "]" + record[0] + ":" + r2+"]" + "N"
            alt2 = "N" + "[" + record[0] + ":" + r1+"["
            # 1
            record[1] = r1
            record[2] = ID + "_" + r1+":1"
            out_put.write('\t'.join(record))
            # 2
            record[1] = r2
            record[2] = ID + "_" + r1+":2"
            record[4] = alt2
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

