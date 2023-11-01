#!/usr/bin/env python3

import argparse
import csv
import json
import sys

def parse_blast_output(blast_output):
    """
    """
    blast_results = []
    with open(blast_output, 'r') as f:
        reader = csv.DictReader(f, dialect='unix')
        for row in reader:
            segment = None
            region = None
            subject_seq_id = row['subject_seq_id']
            subject_seq_id_split = subject_seq_id.split('_')
            if len(subject_seq_id_split) > 1:
                genotype  = subject_seq_id_split[0]
                accession = subject_seq_id_split[-2]
                region    = subject_seq_id_split[-1]
            row['subject_accession'] = accession
            row['genotype'] = genotype
            row['region'] = region
            blast_results.append(row)

    return blast_results


def main(args):
    blast_results = parse_blast_output(args.input)
    writer = csv.DictWriter(sys.stdout, fieldnames=blast_results[0].keys(), dialect='excel-tab')
    writer.writeheader()
    for row in blast_results:
        writer.writerow(row)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='')
    parser.add_argument('-i', '--input')
    args = parser.parse_args()
    main(args)
