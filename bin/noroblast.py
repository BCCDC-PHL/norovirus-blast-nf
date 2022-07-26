#!/usr/bin/env python3

import argparse
import sys as sys
import os as os
import subprocess as sp
import shutil as sh
import pandas as pd

def main(args):

    make_out_dir(args.output)
    #trim reads
    blast_out = align_contigs_to_ref_seqs(args.output, args.input, args.db)
    blast_results = parse_alignments(args.output, blast_out)
    exit(0)


def run(terminal_command, error_msg, stdout_file, stderr_file):
    '''Runs terminal command and directs stdout and stderr into indicated files.'''
    log_files = {}
    for file, dest in zip([stdout_file, stderr_file], ['stdout', 'stderr']):
        if file != None:
            log_files[dest] = open(file, 'w')
            log_files[dest].write('*' * 80 + '\n')
            log_files[dest].write('Terminal command:\n')
            log_files[dest].write(terminal_command + '\n')
            log_files[dest].write('*' * 80 + '\n')
        else:
            log_files[dest] = None
    completed_process = sp.run(terminal_command, stdout=log_files['stdout'], stderr=log_files['stderr'], shell=True)        
    for file in zip([stdout_file, stderr_file], ['stdout', 'stderr']):
        if file != None:
            log_files[dest].close()
    if completed_process.returncode != 0:
        print('\nERROR:', error_msg)
        exit(1)
    return completed_process

def make_out_dir(out_dir):
    '''Creates output dir and a dir for logs within.'''
    print('Creating directory for output...')
    if os.path.exists(out_dir) == False:
        os.mkdir(out_dir)
        logs_path = os.path.join(out_dir, 'logs')
        os.mkdir(logs_path)
    else:
        if os.path.isdir(out_dir) == False:
            print('\nERROR: Cannot create output directory because a file with that name already exists.')
            exit(1)
        if not os.listdir(out_dir):
            print('\nWARNING: Output directory already exists but is empty. Analysis will continue.')
            os.mkdir(out_dir)
            logs_path = os.path.join(out_dir, 'logs')
            os.mkdir(logs_path)
        else:
            print('\nERROR: Output directory already exists and is not empty.')
            exit(1)


def align_contigs_to_ref_seqs(output, contigs, ref_seqs_db):
    '''Align contigs to reference sequences with BLASTn. Returns path to BLASTn results in TSV file.'''
    print(f'Aligning contigs to ref seqs in {ref_seqs_db}...')
    #if any([os.path.exists(ref_seqs_db + '.' + suffix) == False for suffix in ['nhr', 'nin' , 'nsq']]):
    #    print(f'WARNING: blastn db files do not exist for {ref_seqs_db}. Creating blastn db files...')
    terminal_command = (f'makeblastdb -in {ref_seqs_db} -dbtype nucl')
    error_msg = f'blastn terminated with errors while making db for ref seqs. Please refer to /{output}/logs/ for output logs.'
    stdout_file = os.path.join(output, 'logs', output + '_make_blast_db_stdout.txt')
    stderr_file = os.path.join(output, 'logs', output + '_make_blast_db_stderr.txt')
    run(terminal_command, error_msg, stdout_file, stderr_file)
    blast_out = os.path.join(output, output + '_blast_results.tsv')
    terminal_command = (f'blastn -query {contigs} -db {ref_seqs_db} -outfmt'
                        f' "6" > {blast_out}')
    error_msg = f'blastn terminated with errors while aligning contigs to ref seqs. Please refer to /{output}/logs/ for output logs.'
    stdout_file = None
    stderr_file = os.path.join(output, 'logs', output + '_contigs_blast_stderr.txt')
    run(terminal_command, error_msg, stdout_file, stderr_file)
    if os.path.getsize(blast_out) == 0:
        print('\nDONE: No contigs aligned to ref seqs.')
        exit(0)        
    return blast_out


def parse_alignments(output, blast_out):
    cols = 'Query Id;Subject Id;% Identical;Length;Mismatch;Gaps-openings;Q.Start;Q.End;S.Start;S.end;E-value;Bit Score'.split(';')
    blast_results = pd.read_csv(blast_out, sep='\t', names=cols)


    blast_results['Region'] = blast_results['Subject Id'].apply(lambda x: x.split('_')[-1])
    blast_results['Seg'] = blast_results['Subject Id'].apply(lambda x:x.split('_')[0])
    blast_results = blast_results.sort_values(by=['Bit Score'],ascending=False)
    blast_results = blast_results[blast_results['% Identical']>=80]

    #seperate regions:
    #blast_results_rb = blast_results.loc[blast_results['Region']=='RegionB']
    #keep only best match for each contig for each region
    best_bitscores = blast_results[['Query Id','Region', 'Bit Score']].groupby(['Query Id','Region']).max().reset_index()
    blast_results1 = pd.merge(blast_results, best_bitscores, on=['Query Id', 'Bit Score','Region'])
    #drop duplicates for same seg, although subject id is different.
    #blast_results1 = blast_results1.drop_duplicates(subset=['Query Id','Bit Score','Region','Seg'])
    outfile = os.path.join(output,output + '_top1_blast_results.csv')
    blast_results1.to_csv(outfile)

  
    top10_bitscores = blast_results[['Query Id','Region', 'Bit Score']].groupby(['Query Id','Region']).head(10)
    top10_bitscores = top10_bitscores.drop_duplicates()
    blast_results1 = pd.merge(blast_results, top10_bitscores, on=['Query Id', 'Bit Score','Region'])
    #drop duplicates for same seg, although subject id is different.
    #blast_results1 = blast_results1.drop_duplicates(subset=['Query Id','Bit Score','Region','Seg'])

    outfile_10 = os.path.join(output,output + '_top10_blast_results.csv')
    blast_results1.to_csv(outfile_10)

    #regionB = blast_results1[blast_results1['Region']=="RegionB"]
    #regionC = blast_results1[blast_results1['Region']=="RegionC"]
    #rB_outfile = os.path.join(output,output + '_top10_regionB.csv')
    #rC_outfile = os.path.join(output,output + '_top10_regionC.csv')
    #regionB.to_csv(rB_outfile)
    #regionC.to_csv(rC_outfile)



if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument('--input')
    parser.add_argument('-o','--output')
    #parser.add_argument('-t', '--top10',default = 'no')
    parser.add_argument('--db')
    args = parser.parse_args()
    main(args)