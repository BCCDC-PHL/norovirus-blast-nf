#!/usr/bin/env python3
import os, pandas as pd 
from datetime import datetime
import argparse 

def split_blast_df(input_file, output_prefix, regions, dupl_columns, sort_columns ):

    todaydate = datetime.today().strftime('%Y-%m-%d')

    blast_results = pd.read_csv(input_file)
    blast_results = blast_results.drop_duplicates(subset=dupl_columns, keep="first")

    #order by query id
    blast_results = blast_results.sort_values(sort_columns, ascending=[True, False])

    for region in regions:
        region_df = blast_results.loc[blast_results['Region'] == region].copy()
        outpath = os.path.join(f"{output_prefix}_{region}_{todaydate}.csv")
        region_df.to_csv(outpath,index=False)

def get_args():
    parser = argparse.ArgumentParser()
    parser.add_argument('-i', '--input', required=True, help='BLAST results file to split into separate files')
    parser.add_argument('-r', '--regions', default='RegionB,RegionC', help='Comma separated list of region names to search for')
    parser.add_argument('-o', '--outname', required=True, help='Prefix of the output files')
    return parser.parse_args()


def main():
    args = get_args()

    dupl_columns = ['Query Id','Subject Id', 'Region','Seg']
    sort_columns = ['Query Id','Bit Score']

    split_blast_df(args.input, args.outname, args.regions.split(','), dupl_columns, sort_columns)

if __name__ == '__main__':
    main()