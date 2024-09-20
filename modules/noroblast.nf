process noroblast {

    tag {sample_id}

    publishDir "${params.outdir}/${sample_id}", pattern: "${sample_id}/${sample_id}*", mode:'copy', saveAs: { filename -> filename.split("/").last() }
    publishDir "${params.outdir}/${sample_id}", pattern: "${sample_id}/logs", mode:'copy', saveAs: { filename -> filename.split("/").last() }


    input:
    tuple val(sample_id), path(sequences), path(ref)

    output:
    tuple val(sample_id), path("${sample_id}/${sample_id}*.csv"), emit: parsed_results, optional: true
    tuple val(sample_id), path("${sample_id}/${sample_id}_blast_results.tsv"), emit: blast_report, optional: true
    tuple val(sample_id), path("${sample_id}/logs"), emit: logs

    """
    noroblast.py --input ${sequences} -o ${sample_id} --db ${ref}

    """

}
