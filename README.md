# ChIP–BrDU Sequencing Analysis Suite

An R-based end-to-end analysis and visualization suite for paired-end *Saccharomyces cerevisiae* ChIP-seq and BrDU-seq experiments. It combines primary read processing with publication-oriented genome-wide, regional, rDNA, peak and genomic-element reports, while also supporting direct ChIP–BrDU comparisons.

> **Release status:** `v1.0.0-rc1` is a release candidate intended for independent testing on the laboratory macOS/`ngsAnalyser` environment. Validate results before using the suite for a final publication.

## What the suite provides

- A common primary-analysis function for ChIP-seq and BrDU-seq.
- `generic`, `malign` and rDNA-specific (`mrdna`) alignment workflows.
- Strand-collapsed and strand-separated profiles where supported.
- Whole-genome, coordinate-defined regional and exact two-repeat rDNA plots.
- Average enrichment profiles over five calculated peak classes.
- Average profiles, boxplots and heatmaps for curated genomic elements or calculated peak classes.
- Statistical side-by-side boxplot comparisons for selected element or peak cohorts.
- A focused early-versus-late origin report with comparative boxplot p-values.
- Paired ChIP–BrDU regional and genomic-element comparisons with separate y-axes.
- A complete-analysis wrapper that runs primary analysis and the standard downstream report set.

Plotters consume the saved ratio tables and peak calls produced by the primary analysis. They do not simulate reads, call peaks again or apply an additional noise filter. Spline smoothing is used only for graphical presentation of average profiles.

## Download

The complete ready-to-run package includes large Bowtie2 and Rsubread indexes that cannot be stored in ordinary Git history. Download the complete bundle from the repository's [Releases](https://github.com/MohammedAlMamun/chip-brdu-seq-analysis-suite/releases) page when the `v1.0.0-rc1` asset is available.

A source-code clone contains the scripts, documentation and genomic-element annotations, but not the generated reference indexes:

```bash
git clone https://github.com/MohammedAlMamun/chip-brdu-seq-analysis-suite.git
```

For routine analysis, use the release ZIP and keep its internal folder structure unchanged.

## Requirements

The release candidate targets laboratory macOS computers with `ngsAnalyser.app` installed under `/Applications/ngsAnalyser.app`. The primary workflow uses the Bowtie2, Samtools and Bedtools executables supplied by that application.

The R workflow uses packages from CRAN and Bioconductor, including `data.table`, `tidyverse`, `Rsubread`, `ShortRead`, `csaw`, `GenomicAlignments`, `IRanges`, `ORFik`, `BSgenome.Scerevisiae.UCSC.sacCer3`, `readxl`, `gridExtra`, `plotrix`, `viridisLite` and the other packages loaded by the primary-analysis function.

Inputs are paired-end FASTQ files for:

- the experiment's input/control library; and
- the ChIP or BrDU assay library.

## Folder contract

The main script resolves every support path relative to its own location. Preserve this arrangement when moving or sharing the project:

```text
ChIPBrDU-Seq-Analysis-Suite-v1.0.0-rc1/
├── ChIPseq_BrDUseq_Project.R
├── Run_ChIPseq_BrDUseq_Project.R
└── chip_brdu_support/
    ├── genomic_elements/
    └── reference_genome_index/
```

Do not move the main script away from `chip_brdu_support`. Analysis results may be written elsewhere.

## Quick start

1. Download and unzip the complete release bundle.
2. Open `Run_ChIPseq_BrDUseq_Project.R` in RStudio.
3. Execute **Block 1** to source the main script.
4. Edit paths and arguments in one desired analysis call.
5. Execute only that call or block.

The calls in the run script are active examples with placeholder paths. Do not source the entire run script unchanged.

A complete ChIP analysis begins with:

```r
ChIP_BrDU_Complete_Analysis(
  Input_R1="/full/path/to/input_R1.fastq.gz",
  Input_R2="/full/path/to/input_R2.fastq.gz",
  Assay_R1="/full/path/to/chip_R1.fastq.gz",
  Assay_R2="/full/path/to/chip_R2.fastq.gz",
  Assay="ChIP",
  Alignment="generic",
  ExpTitle="SampleName",
  Directory="/full/path/to/ChIP_results",
  StrandModes=c("collapsed", "separated"),
  Elements=c("EarlyOrigin", "LateOrigin"),
  Regions=NULL
)
```

Use `Assay="BrDU"` and BrDU FASTQs for the corresponding BrDU workflow. `ExpTitle` should contain the biological sample name only; the assay marker is added to relevant output filenames by the pipeline.

See [Quick start](docs/QUICK_START.md) for analysis modes and practical examples.

## Signals and metrics

The saved ratio tables expose four standard metrics:

| Metric | Plot label | Neutral baseline |
|---|---|---:|
| `ip.score` | ChIP/BrDU coverage | 0 |
| `ratio.ipin` | Assay over input | 1 |
| `ratio.ipnoise` | Assay over noise | 1 |
| `ratio.ipin.noise` | Clean enrichment | 1 |

Log2 transformation is optional in the relevant collapsed-profile functions. Where log2 values are shown, ratio baselines map from 1 to 0. Strand-separated whole-genome profiles remain untransformed by design.

## Genomic cohorts

Curated selectors include:

`ARS`, `EarlyOrigin`, `LateOrigin`, `TER`, `Ty`, `tRNA`, `Centromere`, `Convergent`, `Divergent`, `CTrans` and `WTrans`.

Calculated peak selectors include:

`GenomewidePeaks`, `NonOriginPeaks`, `OriginPeaks`, `EarlyOriginPeaks` and `LateOriginPeaks`.

Peak cohorts use the saved primary-analysis peak files and are centred on `peakSummit`. `chrM` is excluded from genomic-element analyses.

## Documentation

- [Quick start and workflow selection](docs/QUICK_START.md)
- [Function reference](docs/FUNCTION_REFERENCE.md)
- [Outputs and report organization](docs/OUTPUTS.md)
- [Support files and reference scope](docs/SUPPORT_FILES.md)
- [Troubleshooting](docs/TROUBLESHOOTING.md)
- [Frequently asked questions](docs/FAQ.md)

## Support

Use [GitHub Issues](https://github.com/MohammedAlMamun/chip-brdu-seq-analysis-suite/issues) for reproducible defects. Include the function call with paths anonymized, assay and alignment mode, the complete error message, R version, macOS version, and the generated `Analysis_Manifest.tsv` where applicable. Do not upload FASTQs or confidential experimental data.

## Current scope and limitations

- References and genomic annotations are specific to *S. cerevisiae* S288C/sacCer3.
- The current primary workflow expects paired-end reads.
- Executable paths currently target the laboratory `ngsAnalyser.app` macOS installation.
- The `mrdna` workflow uses the bundled custom 18,274-bp two-repeat reference. Its second repeat is an exact duplicate of the first custom repeat, not the native second SGD repeat.
- This RC has been developed and trialled on representative laboratory output but does not yet have automated continuous-integration tests with distributable sequencing data.

## Roadmap

A future graphical application is planned around the existing run-script organization, with dedicated Complete analysis, ChIP, BrDU and Comparative analysis views. The application is not part of this release candidate.

## Citation and provenance

Citation metadata is provided in [`CITATION.cff`](CITATION.cff). Detailed annotation provenance and preserved source inconsistencies are documented in [`chip_brdu_support/genomic_elements/README_annotations.txt`](chip_brdu_support/genomic_elements/README_annotations.txt).

## License

No software license has yet been assigned. Until a license is added, copyright remains with the author and reuse beyond downloading and testing requires permission.
