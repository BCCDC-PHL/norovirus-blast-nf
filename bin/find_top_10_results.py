#!/usr/bin/env python3

import argparse
import csv
import json
import sys

def parse_blast_output(blast_output_path):
    """
    Parse blast output (tsv format)

    :param blast_output_path: Path to blast output file (tsv format)
    :type blast_output_path: str
    :return: A list of dictionaries. Values are not cast to numeric types, left as strings.
    :rtype: list[dict[str, str]]
    """
    blast_output = []
    with open(blast_output_path, 'r') as f:
        reader = csv.DictReader(f, dialect='excel-tab')
        for row in reader:
            blast_output.append(row)

    return blast_output

def main(args):
    blast_results = parse_blast_output(args.input)
    blast_results_sorted_by_bitscore = sorted(blast_results, key=lambda x: int(x['bitscore']), reverse=True)
    top_10_alignments_by_bitscore = blast_results_sorted_by_bitscore[:10]
    
    writer = csv.DictWriter(sys.stdout, fieldnames=blast_results[0].keys(), dialect='unix', quoting=csv.QUOTE_MINIMAL)
    writer.writeheader()
    for row in top_10_alignments_by_bitscore:
        writer.writerow(row)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='')
    parser.add_argument('-i', '--input')
    args = parser.parse_args()
    main(args)
