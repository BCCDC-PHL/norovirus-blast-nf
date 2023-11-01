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


def group_by(lst, key):
    """
    Group a list of dictionaries by the values associated with a specific key.

    :param lst:
    :type lst: list[dict[str, object]]
    :param key:
    :type key: str
    :return:
    :rytpe: dict[str, list[dict]]
    """
    grouped = {}
    for l in lst:
        if key in l:
            if l[key] not in grouped:
                grouped[l[key]] = [l]
            else:
                grouped[l[key]].append(l)

    return grouped


def main(args):
    blast_results = parse_blast_output(args.input)
    blast_results_grouped_by_region = group_by(blast_results, 'region')
    top_result_by_region = []
    for region, blast_results in blast_results_grouped_by_region.items():
        blast_results_sorted = sorted(blast_results, key=lambda x: x['bitscore'], reverse=True)
        top_result_by_region.append(blast_results_sorted[0])
    
    writer = csv.DictWriter(sys.stdout, fieldnames=blast_results[0].keys(), dialect='unix', quoting=csv.QUOTE_MINIMAL)
    writer.writeheader()
    for row in top_result_by_region:
        writer.writerow(row)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='')
    parser.add_argument('-i', '--input')
    args = parser.parse_args()
    main(args)
