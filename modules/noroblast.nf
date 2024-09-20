process noroblast {

    tag {sample_id}

    publishDir "${params.outdir}/${sample_id}", pattern: "${sample_id}/${sample_id}*", mode:'copy', saveAs: { filename -> filename.split("/").last() }
    publishDir "${params.outdir}/${sample_id}", pattern: "${sample_id}/logs", mode:'copy', saveAs: { filename -> filename.split("/").last() }


    input:
    tuple val(sample_id), path(sequences), path(ref)

    output:
    tuple val(sample_id), path("${sample_id}/${sample_id}_blast_results.tsv")       , emit: blast_report, optional: true
    tuple val(sample_id), path("${sample_id}/${sample_id}*_top10_*.csv")            , emit: top10, optional: true
    tuple val(sample_id), path("${sample_id}/${sample_id}*_top1_*.csv")             , emit: top1, optional: true
    tuple val(sample_id), path("${sample_id}/logs"), emit: logs

    """
    noroblast.py --input ${sequences} -o ${sample_id} --db ${ref}

    """

}

process split_blast_outputs {

    publishDir "${params.outdir}", pattern: "*csv", mode:'copy'


    input:
    path(top1_results)
    path(top10_results)

    output:
    path("${params.run_name}_top1_*csv")                  , emit: top1, optional: true
    path("${params.run_name}_top10_*csv")                 , emit: top10, optional: true

    """
    split_blast.py --input ${top1_results} --outname ${params.run_name}_top1

    split_blast.py --input ${top10_results} --outname ${params.run_name}_top10
    """

}