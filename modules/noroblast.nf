process seq_qc {

    tag { sample_id }

    executor 'local'

    publishDir "${params.outdir}/${sample_id}", mode: 'copy', pattern: "${sample_id}_seq_qc.csv"

    input:
    val(seq)

    output:
    tuple val(sample_id), path("${sample_id}_seq_qc.csv")

    script:
    sample_id = seq.id
    """
    echo ">${sample_id}" > ${sample_id}.fa
    echo "${seq.seqString}" >> ${sample_id}.fa

    seq_qc.py -i ${sample_id}.fa --sample-id ${sample_id} > ${sample_id}_seq_qc.csv
    """
}


process blastn {

    errorStrategy 'ignore'

    tag { sample_id }

    publishDir "${params.outdir}/${sample_id}", mode: 'copy', pattern: "${sample_id}*"

    input:
    tuple val(seq), path(db)

    output:
    tuple val(sample_id), path("${sample_id}_blast_results.tsv"), emit: blast_report, optional:true
    
    script:
    sample_id = seq.id
    """
    echo ">${sample_id}" > ${sample_id}.fa
    echo "${seq.seqString}" >> ${sample_id}.fa

    echo "query_seq_id,subject_seq_id,subject_strand,query_length,query_start,query_end,subject_length,subject_start,subject_end,alignment_length,percent_identity,percent_coverage,num_mismatch,num_gaps,e_value,bitscore" > ${sample_id}_blast.csv

    blastn \
	-subject ${db} \
	-num_threads ${task.cpus} \
	-perc_identity ${params.minid} \
	-qcov_hsp_perc ${params.mincov} \
	-query ${sample_id}.fa \
	-outfmt "6 qseqid saccver sstrand qlen qstart qend slen sstart send length pident qcovhsp mismatch gaps evalue bitscore" \
	| tr \$"\\t" "," >> ${sample_id}_blast.csv

    parse_blast_output.py -i ${sample_id}_blast.csv > ${sample_id}_blast_results.tsv
    """
}


process find_top_results {

    tag { sample_id }

    executor 'local'

    publishDir "${params.outdir}/${sample_id}", mode: 'copy', pattern: "${sample_id}_*.csv"

    input:
    tuple val(sample_id), path(blast_output)

    output:
    tuple val(sample_id), path("${sample_id}_top_result_by_region.csv"), emit: top_result_by_region
    tuple val(sample_id), path("${sample_id}_top_10_results.csv"), emit: top_10_results

    script:
    """
    find_top_results_by_region.py -i ${blast_output} > ${sample_id}_top_result_by_region.csv
    find_top_10_results.py -i ${blast_output} > ${sample_id}_top_10_results.csv
    """

}


process noroblast {

    tag {sample_id}

    publishDir "${params.outdir}/${sample_id}", pattern: "${sample_id}/${sample_id}*", mode:'copy', saveAs: { filename -> filename.split("/").last() }
    publishDir "${params.outdir}/${sample_id}", pattern: "${sample_id}/logs", mode:'copy'


    input:
    tuple val(sample_id), path(reads), path(ref)

    output:
    tuple val(sample_id), path("${sample_id}/${sample_id}*.csv"), emit: parsed_results, optional: true
    tuple val(sample_id), path("${sample_id}/${sample_id}_blast_results.tsv"), emit: blast_report, optional: true
    tuple val(sample_id), path("${sample_id}/logs"), emit: logs

    """
    noroblast.py --input ${reads} -o ${sample_id} --db ${ref}

    """

}
