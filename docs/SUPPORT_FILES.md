# Support files

## Reference scope

The bundled support data target *Saccharomyces cerevisiae* S288C/sacCer3. `ChIP_BrDU_Project_Paths(check=TRUE)` validates that required files remain beside the main R script.

## Licensing and attribution

The suite's MIT License covers the original software and documentation, not third-party reference or annotation data. SGD-derived material is distributed under CC BY 4.0 and requires attribution to the Saccharomyces Genome Database. Generated Bowtie2 and Rsubread indexes retain the attribution and terms applicable to their source reference sequences.

Supplied and laboratory-curated feature lists retain their documented provenance and any source-specific terms. See [`THIRD_PARTY_NOTICES.md`](../THIRD_PARTY_NOTICES.md) before redistributing the complete support bundle.

## Repository versus release bundle

The Git repository contains the curated genomic-element files and their retained raw sources. Generated Bowtie2 and Rsubread index binaries are intentionally excluded from Git because several exceed GitHub's ordinary file-size limit.

The complete release ZIP supplies `chip_brdu_support/reference_genome_index` with:

- the S288C FASTA;
- Bowtie2 S288C index files;
- Rsubread S288C index files;
- the exact two-repeat rDNA FASTA; and
- its Rsubread index files.

Do not attempt primary analysis from a source-only clone until this directory has been populated from the matching release bundle.

## Curated genomic elements

The analysis-ready BED files cover ORFs, ARSs, Early and Late origins, termination regions, Ty/LTR elements, tRNAs, centromeres, convergent/divergent regions, Watson/Crick transcribed regions and the exact two-repeat rDNA architecture.

Processed nuclear coordinates use BED convention: zero-based `chromStart` and half-open `chromEnd`. The retained raw sources remain unchanged.

## rDNA reference

`RDNAx2.fasta` is 18,274 bp and consists of two identical 9,137-bp units. The second custom repeat is annotated by duplicating copy-one coordinates by exactly 9,137 bp. It is not substituted with the distinct native second repeat represented by SGD.

The unit boundary falls inside NTS1, so NTS1 and the canonical RFB crossing that boundary are represented with split intervals where necessary.

## Provenance and preserved inconsistencies

The authoritative processing notes, feature counts, SGD source information, coordinate transformations and known discrepancies among the origin lists are documented in [`README_annotations.txt`](../chip_brdu_support/genomic_elements/README_annotations.txt). Those discrepancies were preserved rather than silently reconciled.
