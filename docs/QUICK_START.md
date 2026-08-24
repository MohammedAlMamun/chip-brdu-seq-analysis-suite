# Quick start

## 1. Use the complete release bundle

Download the latest complete ZIP from [Releases](https://github.com/MohammedAlMamun/chip-brdu-seq-analysis-suite/releases). Unzip it locally without renaming or separating the two R scripts and `chip_brdu_support` folder.

The source-code archive generated automatically by GitHub does not contain the generated reference indexes and is therefore not a replacement for the complete release bundle when running primary analysis.

## 2. Load the suite

Open `Run_ChIPseq_BrDUseq_Project.R` in RStudio and execute Block 1. It locates and sources `ChIPseq_BrDUseq_Project.R` relative to the run script.

If working from another script, an explicit source call is also valid:

```r
source("/full/path/to/ChIPBrDU-Seq-Analysis-Suite/ChIPseq_BrDUseq_Project.R")
```

Confirm the bundle is intact:

```r
ChIP_BrDU_Project_Paths(check=TRUE)
```

## 3. Choose an alignment mode

| Mode | Purpose | Reference/alignment behavior |
|---|---|---|
| `generic` | Standard nuclear-genome analysis | Bowtie2-based primary alignment |
| `malign` | Multi-alignment-aware nuclear-genome analysis | Rsubread multi-alignment workflow |
| `mrdna` | Dedicated rDNA analysis | Rsubread alignment against the exact two-repeat rDNA reference, using genome-wide multi-alignment noise estimation |

The downstream whole-genome and genomic-element plotters accept `generic` or `malign`. Use `ChIP_BrDU_rDNA_Plotter()` for `mrdna` output.

## 4. Run one analysis call

Replace every placeholder path before execution. A sample name is supplied without an assay suffix:

```r
ChIP_BrDU_Primary_Analysis(
  Input_R1="/data/sample_input_R1.fastq.gz",
  Input_R2="/data/sample_input_R2.fastq.gz",
  Assay_R1="/data/sample_chip_R1.fastq.gz",
  Assay_R2="/data/sample_chip_R2.fastq.gz",
  Assay="ChIP",
  Alignment="generic",
  ExpTitle="SampleName",
  Directory="/data/analysis"
)
```

For a primary analysis followed by the standard downstream reports, use `ChIP_BrDU_Complete_Analysis()` instead.

## 5. Replot existing results

Plotters read the saved ratio and peak folders under a completed sample directory. They do not require FASTQs and do not repeat primary analysis.

```r
ChIP_BrDU_Early_Late_Enrichment_Plotter(
  SampleDir="/data/analysis/SampleName",
  Assay="ChIP",
  Alignment="generic",
  StrandMode="collapsed",
  Log2Profile=FALSE,
  Window=3000
)
```

Multiple completed sample directories may be supplied to the region and rDNA plotters where their `SampleDir` and `SampleLabels` arguments support comparison.

## 6. Customize the principal display choices

- `Window` sets the half-window in base pairs for peak/element-centred reports.
- `WindowSizeKb` sets the whole-genome panel window in kilobases.
- `Metric` selects one metric or `"all"` where supported.
- `Log2Profile` or `Log2Values` controls transformation where supported.
- `y_val` fixes the plotting range when automatic scaling needs visual adjustment.
- `y_val_chip` and `y_val_brdu` independently control paired comparison axes.
- `PlotStyle` selects histogram-style bars or lines in regional/profile functions that expose it.
- `OutputDir` redirects reports without changing the input sample directory.

Graphical details that should remain consistent across experiments are intentionally internal to the functions.
