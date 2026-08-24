# Third-party notices

The MIT License in [`LICENSE`](LICENSE) applies to the original ChIP–BrDU Sequencing Analysis Suite software and its original documentation. It does not relicense third-party software, reference sequences, annotations, or supplied scientific datasets.

## Saccharomyces Genome Database material

Reference and annotation material obtained or derived from the Saccharomyces Genome Database (SGD) is provided under the [Creative Commons Attribution 4.0 International License](https://creativecommons.org/licenses/by/4.0/) and must retain attribution to SGD.

- Source: [Saccharomyces Genome Database](https://www.yeastgenome.org/)
- Download archive: [SGD Downloads](http://sgd-archive.yeastgenome.org/)
- Assembly used by this suite: S288C/sacCer3, with exact source and transformation details recorded in [`chip_brdu_support/genomic_elements/README_annotations.txt`](chip_brdu_support/genomic_elements/README_annotations.txt)

The bundled custom rDNA FASTA and annotation are derived from the documented S288C reference interval and include an exact duplicated custom repeat. Redistribution or adaptation of SGD-derived material must preserve the required source attribution.

## Generated reference indexes

The complete release bundle contains generated Bowtie2 and Rsubread index files derived from the bundled reference sequences. These index artifacts are provided for reproducible execution of the suite and remain subject to the applicable terms and attribution requirements of their source reference data.

Bowtie2 and Rsubread software are not redistributed by this repository or release bundle. The generated index files do not change or replace the licenses of those external tools.

## External software dependencies

The primary workflow calls executables supplied by the separately installed `ngsAnalyser.app`, including Bowtie2, Samtools and Bedtools, and uses R and Bioconductor/CRAN packages including Rsubread. Those programs and packages remain under their respective upstream licenses and are not covered by this repository's MIT License.

Users and redistributors are responsible for complying with the licenses of their installed external dependencies.

## Supplied and laboratory-curated genomic feature files

The support folder also preserves supplied or laboratory-curated feature lists and their processed derivatives. Their provenance, coordinate transformations and preserved source inconsistencies are documented in [`chip_brdu_support/genomic_elements/README_annotations.txt`](chip_brdu_support/genomic_elements/README_annotations.txt).

Unless a file is identified as original suite software or documentation, inclusion in the repository does not assert that the file has been relicensed under MIT. Redistribution must follow the terms of its original source and any applicable institutional or collaborator agreement.
