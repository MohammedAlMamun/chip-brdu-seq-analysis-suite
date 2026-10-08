# ChIP–BrDU Sequencing Analysis Suite: complete function vignette

This vignette documents every user-callable function in `ChIPseq_BrDUseq_Project.R`. It explains what each function does, when it should be used, every public argument, and the principal result it writes or returns.

The main script also contains many local helper functions. Those helpers are implementation details created inside the public functions and are intentionally not part of the supported user interface.

## Contents

1. [Before running a function](#before-running-a-function)
2. [Common selectors and conventions](#common-selectors-and-conventions)
3. [`ChIP_BrDU_Project_Paths()`](#chip_brdu_project_paths)
4. [`ChIP_BrDU_Primary_Analysis()`](#chip_brdu_primary_analysis)
5. [`ChIP_BrDU_Complete_Analysis()`](#chip_brdu_complete_analysis)
6. [`ChIP_BrDU_WholeGenome_Plotter()`](#chip_brdu_wholegenome_plotter)
7. [`ChIP_BrDU_Region_Plotter()`](#chip_brdu_region_plotter)
8. [`ChIP_BrDU_rDNA_Plotter()`](#chip_brdu_rdna_plotter)
9. [`ChIP_BrDU_Peak_Enrichment_Plotter()`](#chip_brdu_peak_enrichment_plotter)
10. [`ChIP_BrDU_Genomic_Element_Enrichment_Plotter()`](#chip_brdu_genomic_element_enrichment_plotter)
11. [`ChIP_BrDU_Early_Late_Enrichment_Plotter()`](#chip_brdu_early_late_enrichment_plotter)
12. [`ChIP_BrDU_Genomic_Element_Boxplotter()`](#chip_brdu_genomic_element_boxplotter)
13. [`ChIP_BrDU_Genomic_Element_Heatmap_Plotter()`](#chip_brdu_genomic_element_heatmap_plotter)
14. [`ChIP_BrDU_Region_Comparison_Plotter()`](#chip_brdu_region_comparison_plotter)
15. [`ChIP_BrDU_Enrichment_Comparison_Plotter()`](#chip_brdu_enrichment_comparison_plotter)
16. [`ChIP_BrDU_TimeSeries_Analysis()`](#chip_brdu_timeseries_analysis)
17. [Recommended workflow](#recommended-workflow)

<a id="before-running-a-function"></a>

## Before running a function

Keep the main script and support folder together:

```text
ChIPBrDU-Seq-Analysis-Suite/
├── ChIPseq_BrDUseq_Project.R
├── Run_ChIPseq_BrDUseq_Project.R
└── chip_brdu_support/
    ├── genomic_elements/
    └── reference_genome_index/
```

Open `Run_ChIPseq_BrDUseq_Project.R` in RStudio and execute Block 1, or source the main script explicitly:

```r
source("/full/path/to/ChIPBrDU-Seq-Analysis-Suite/ChIPseq_BrDUseq_Project.R")
```

All downstream plotters read final ratio tables, peak calls, or annotations already produced by the primary workflow. They do not simulate data, repeat noise filtering, recalculate ratios, or call peaks again.

<a id="common-selectors-and-conventions"></a>

## Common selectors and conventions

### Assays

```r
Assay = "ChIP"
Assay = "BrDU"
```

`Assay` chooses the assay-specific file names and plot labels. A ChIP sample does not require a sister BrDU sample, and a BrDU sample does not require a sister ChIP sample except in the two explicit comparison functions.

### Alignment modes

| Value | Meaning | Principal saved folders |
|---|---|---|
| `"generic"` | Standard nuclear-genome Bowtie2 workflow. | `Bam`, `Coverage`, `Peaks`, `Ratios` |
| `"malign"` | Multi-alignment-aware nuclear-genome Rsubread workflow. | `Bam_ma`, `Coverage_ma`, `Peaks_ma`, `Ratios_ma` |
| `"mrdna"` | Dedicated Rsubread analysis against the exact custom two-repeat rDNA reference, with genome-wide multi-alignment noise estimation. | `Bam_ma_rdna`, `Coverage_ma_rdna`, `Ratios_ma_rdna` |

Most nuclear-genome plotters accept only `"generic"` or `"malign"`. The dedicated rDNA plotter reads `"mrdna"` output and therefore has no public `Alignment` argument.

### Strand modes

| Value | Meaning |
|---|---|
| `"collapsed"` | Reads the saved strand-collapsed ratio table. Peak visualization is available only where explicitly supported. |
| `"separated"` | Reads the saved Watson and Crick tables; Watson is positive and Crick is mirrored below zero. |

The boxplotter, heatmap plotter, and direct ChIP–BrDU comparison functions are intentionally strand-collapsed only.

### Final ratio-table metrics

| Selector | Panel label | Interpretation |
|---|---|---|
| `"ip.score"` | ChIP/BrDU or Coverage | Saved assay coverage score. Its raw reference floor is 0. |
| `"ratio.ipin"` | Assay / Input | Assay enrichment relative to the input library. Its untransformed neutral baseline is 1. |
| `"ratio.ipnoise"` | Assay / Noise | Assay enrichment relative to the primary workflow's noise estimate. Its untransformed neutral baseline is 1. |
| `"ratio.ipin.noise"` | Clean | Final input- and noise-adjusted enrichment. Its untransformed neutral baseline is 1. |

When a function accepts `Metric="all"`, it plots all four metrics in the order shown above.

### Genomic-element selectors

Curated support-file cohorts:

```r
c(
  "ARS", "EarlyOrigin", "LateOrigin", "TER", "Ty", "tRNA",
  "Centromere", "Convergent", "Divergent", "CTrans", "WTrans"
)
```

Sample-specific peak cohorts:

```r
c(
  "GenomewidePeaks", "NonOriginPeaks", "OriginPeaks",
  "EarlyOriginPeaks", "LateOriginPeaks"
)
```

Curated features are centred on their BED interval midpoint. Peak cohorts are centred on the saved `peakSummit` from the selected sample's primary-analysis peak file. ORFs, rDNA, and `chrM` are excluded from the generic element-centred reports because they require different biological or graphical treatment.

### Coordinates and windows

- `RegionStart` and `RegionEnd` use zero-based, half-open BED-style coordinates: the start is included and the end is excluded.
- `Window` is a half-window in base pairs. For example, `Window=3000` plots or summarizes 3,000 bp on each side of the feature centre.
- `WindowSizeKb` is the whole-genome panel width in kilobases.
- Missing bins near chromosome ends remain missing; element-centred functions do not interpolate or add zero padding.

### Display transformations

Transformations and spline smoothing are graphical operations only. The saved ratio tables are never overwritten.

- In untransformed ratio panels, the neutral baseline is 1.
- In log2 ratio panels, the neutral baseline is 0.
- Functions that support separated log transformation use the behavior documented in their own section.
- `y_val=NULL`, `y_val_chip=NULL`, or `y_val_brdu=NULL` retains automatic axis calculation.

<a id="chip_brdu_project_paths"></a>

## 1. `ChIP_BrDU_Project_Paths()`

Resolves every project support path relative to the location of the main R script. Use it to confirm that a copied or downloaded bundle still contains all required indexes and genomic-element files.

```r
ChIP_BrDU_Project_Paths(check=TRUE)
```

### Arguments

| Argument | Default | Explanation |
|---|---:|---|
| `check` | `TRUE` | When `TRUE`, verifies the required support directories, reference files, indexes, and processed BED files. Use `FALSE` only to inspect the resolved path list without enforcing completeness. |

### Result

Returns a named list containing the main-script path, project and support directories, reference-index paths, and processed genomic-element paths. With `check=TRUE`, an incomplete or incorrectly arranged bundle stops with a list of missing items.

### Example

```r
paths <- ChIP_BrDU_Project_Paths(check=TRUE)
paths$reference_genome_index_dir
paths$elements$early_origins
```

<a id="chip_brdu_primary_analysis"></a>

## 2. `ChIP_BrDU_Primary_Analysis()`

Runs the established primary ChIP-seq or BrDU-seq workflow: alignment, binned strand-aware coverage, genome-wide noise estimation, filtration, peak calling, and final ratio-table generation. Use it when starting from paired-end FASTQs and when downstream reports will be run separately.

```r
ChIP_BrDU_Primary_Analysis(
  Input_R1="/full/path/to/input_R1.fastq.gz",
  Input_R2="/full/path/to/input_R2.fastq.gz",
  Assay_R1="/full/path/to/assay_R1.fastq.gz",
  Assay_R2="/full/path/to/assay_R2.fastq.gz",
  Assay=c("ChIP", "BrDU"),
  Alignment="generic",
  ExpTitle="Smc5-trial",
  Directory="None",
  slidingWindow="YES"
)
```

### Arguments

| Argument | Default | Explanation |
|---|---|---|
| `Input_R1` | placeholder path | Path to read 1 of the paired-end input/control library. The file must correspond to `Input_R2`. |
| `Input_R2` | placeholder path | Path to read 2 of the paired-end input/control library. Keep the read pairing and sample identity consistent with `Input_R1`. |
| `Assay_R1` | placeholder path | Path to read 1 of the paired-end ChIP or BrDU assay library selected by `Assay`. |
| `Assay_R2` | placeholder path | Path to read 2 of the paired-end assay library. It must be the mate of `Assay_R1`. |
| `Assay` | `c("ChIP", "BrDU")` | Selects ChIP or BrDU processing labels and assay-specific output filenames. Supply one value in a real call. |
| `Alignment` | `"generic"` | Selects `"generic"`, `"malign"`, or `"mrdna"`. Use `mrdna` only for the dedicated custom-rDNA workflow. |
| `ExpTitle` | `"Smc5-trial"` | Defines the experiment/sample folder and output prefix. Use a biological sample name only; the assay name is added separately where required. |
| `Directory` | `"None"` | Parent directory in which the sample folder is created. `"None"` uses the user's Desktop. |
| `slidingWindow` | `"YES"` | Legacy coverage-mode setting retained for workflow compatibility. Keep `"YES"` for the established overlapping 300-bp windows at 10-bp steps used by the suite. |

### Result and output

The function writes the complete primary-analysis directory tree beneath `file.path(Directory, ExpTitle)`. Nuclear workflows produce strand-collapsed, Watson, and Crick ratio tables plus five peak classes; `mrdna` additionally produces the custom-rDNA ratio outputs. This function is disk-output oriented and does not return a structured analysis object for routine use.

### Example

```r
ChIP_BrDU_Primary_Analysis(
  Input_R1="/data/Smc5_Input_R1.fastq.gz",
  Input_R2="/data/Smc5_Input_R2.fastq.gz",
  Assay_R1="/data/Smc5_ChIP_R1.fastq.gz",
  Assay_R2="/data/Smc5_ChIP_R2.fastq.gz",
  Assay="ChIP",
  Alignment="generic",
  ExpTitle="Smc5_60HU",
  Directory="/data/analysis"
)
```

<a id="chip_brdu_complete_analysis"></a>

## 3. `ChIP_BrDU_Complete_Analysis()`

Runs primary analysis and then the standard single-assay report suite in one call. Use it when the desired endpoint is a processed sample directory, a concise manifest, and a collection of downstream multi-page PDFs.

```r
ChIP_BrDU_Complete_Analysis(
  Input_R1="/full/path/to/input_R1.fastq.gz",
  Input_R2="/full/path/to/input_R2.fastq.gz",
  Assay_R1="/full/path/to/assay_R1.fastq.gz",
  Assay_R2="/full/path/to/assay_R2.fastq.gz",
  Assay=c("ChIP", "BrDU"),
  Alignment=c("generic", "malign", "mrdna"),
  ExpTitle="Smc5-trial",
  Directory="None",
  slidingWindow="YES",
  StrandModes=c("collapsed", "separated"),
  Elements=c("EarlyOrigin", "LateOrigin"),
  Regions=NULL,
  ReportDir=NULL,
  ProfileElements=NULL,
  HeatmapXLim=NULL,
  HeatmapZLim=NULL
)
```

### Arguments

| Argument | Default | Explanation |
|---|---|---|
| `Input_R1` | placeholder path | Read 1 of the paired-end input/control library. The wrapper validates that the file exists before starting. |
| `Input_R2` | placeholder path | Read 2 of the paired-end input/control library. It must be paired with `Input_R1`. |
| `Assay_R1` | placeholder path | Read 1 of the ChIP or BrDU assay library. |
| `Assay_R2` | placeholder path | Read 2 of the ChIP or BrDU assay library. |
| `Assay` | `c("ChIP", "BrDU")` | Selects the assay processed in this complete run. Supply exactly one assay. |
| `Alignment` | `c("generic", "malign", "mrdna")` | Selects one primary-analysis modality. Nuclear modes run the standard downstream suite; `mrdna` runs the rDNA report instead. |
| `ExpTitle` | `"Smc5-trial"` | Sample folder name and output prefix. Do not append `-ChIP` or `-BrDU` merely to mark the assay. |
| `Directory` | `"None"` | Parent output directory. `"None"` uses the Desktop, matching the primary function. |
| `slidingWindow` | `"YES"` | Passed to the primary workflow. Keep `"YES"` for the established sliding-window output expected by downstream functions. |
| `StrandModes` | `c("collapsed", "separated")` | One or both strand displays to generate for compatible profile reports. Duplicate values are removed. |
| `Elements` | Early and Late origins | Curated or peak cohorts used by the boxplot and heatmap reports. At least one supported selector is required. |
| `Regions` | `NULL` | Optional data frame with `Chromosome`, `RegionStart`, and `RegionEnd` columns. Each row generates regional reports in the requested strand modes; it is not allowed with `mrdna`. |
| `ReportDir` | `NULL` | Destination for report subfolders and `Analysis_Manifest.tsv`. `NULL` creates `Complete_Analysis_Reports` inside the sample directory. |
| `ProfileElements` | `NULL` | Cohorts used by the genomic-element average-profile report. `NULL` requests the full curated set; a character vector may select curated elements or saved peak cohorts. |
| `HeatmapXLim` | `NULL` | Optional centered genomic-element heatmap half-width in base pairs. The complete run extracts the standard +/-3,000-bp heatmap window, so this value must be no greater than 3,000 and must match the saved sliding-window step. |
| `HeatmapZLim` | `NULL` | Optional genomic-element heatmap saturation limit. One positive value applies to all four metrics, while a named vector can set separate values such as `c(ip.score=10, ratio.ipin=3, ratio.ipnoise=5, ratio.ipin.noise=4)`. |

### Included and excluded reports

For `generic` or `malign`, the wrapper runs peak enrichment, genomic-element enrichment, genomic-element boxplots, genomic-element heatmaps, and any requested regional profiles. `HeatmapXLim` and `HeatmapZLim` are forwarded only to the genomic-element heatmap report and do not alter its extracted matrices or primary results. For `mrdna`, the wrapper runs the exact rDNA profiles and therefore does not accept these heatmap controls.

The wrapper deliberately excludes whole-genome plotting, the focused Early/Late-only report, and both direct ChIP–BrDU comparison functions because those require experiment-specific choices.

### Result

Returns an invisible list with `sample_dir`, `report_dir`, `manifest_file`, the manifest table, completed PDF paths, individual stage results, and a logical `complete` status. A failed downstream stage is recorded in the manifest without discarding reports that completed successfully.

### Example

```r
run <- ChIP_BrDU_Complete_Analysis(
  Input_R1="/data/Smc5_Input_R1.fastq.gz",
  Input_R2="/data/Smc5_Input_R2.fastq.gz",
  Assay_R1="/data/Smc5_ChIP_R1.fastq.gz",
  Assay_R2="/data/Smc5_ChIP_R2.fastq.gz",
  Assay="ChIP",
  Alignment="generic",
  ExpTitle="Smc5_60HU",
  Directory="/data/analysis",
  Elements=c("EarlyOrigin", "LateOrigin", "OriginPeaks"),
  HeatmapXLim=2000,
  HeatmapZLim=c(
    ip.score=10,
    ratio.ipin=3,
    ratio.ipnoise=5,
    ratio.ipin.noise=4
  ),
  Regions=data.frame(
    Chromosome="chrIV",
    RegionStart=400000,
    RegionEnd=500000
  )
)
```

<a id="chip_brdu_wholegenome_plotter"></a>

## 4. `ChIP_BrDU_WholeGenome_Plotter()`

Plots whole chromosomes from a completed nuclear primary analysis with genomic annotations. Collapsed mode can show saved peak-supported signal coloring; separated mode shows Watson above zero and mirrored Crick below zero without peak annotation.

```r
ChIP_BrDU_WholeGenome_Plotter(
  SampleDir,
  Assay=c("ChIP", "BrDU"),
  Alignment=c("generic", "malign"),
  StrandMode=c("collapsed", "separated"),
  Metric=c("ratio.ipin.noise", "ratio.ipin", "ratio.ipnoise", "ip.score"),
  Chromosomes="all",
  WindowSizeKb=50,
  PlotStyle=c("hist", "lines"),
  y_val=NULL,
  OutputDir=NULL
)
```

### Arguments

| Argument | Default | Explanation |
|---|---|---|
| `SampleDir` | required | One completed sample directory containing the appropriate `Ratios`/`Ratios_ma` and, for collapsed peak display, `Peaks`/`Peaks_ma` folders. |
| `Assay` | ChIP or BrDU | Selects which assay-prefixed ratio and peak files are read. |
| `Alignment` | generic or malign | Selects the standard or multi-alignment nuclear output folders. |
| `StrandMode` | collapsed or separated | Chooses one collapsed table or the paired Watson/Crick tables. Separated mode is always untransformed and omits peak coloring and peak annotation. |
| `Metric` | `"ratio.ipin.noise"` first | Selects one saved ratio-table column for the genome profile. Collapsed profiles use the established log2 display; separated profiles retain raw non-negative ratios before Crick mirroring. |
| `Chromosomes` | `"all"` | `"all"` plots nuclear chromosomes I–XVI. A chromosome name, number, or vector such as `c("chrIII", "chrIV")` restricts the report; `chrM` can be requested explicitly. |
| `WindowSizeKb` | `50` | Width in kilobases of each consecutive plotting panel along a chromosome. It changes graphical segmentation, not the primary ratio-table resolution. |
| `PlotStyle` | `"hist"` first | `"hist"` draws bar-style profiles and `"lines"` draws continuous lines. |
| `y_val` | `NULL` | Manual upper limit. In collapsed mode it sets the positive upper boundary; in separated mode it creates symmetric `-y_val` to `+y_val` limits. |
| `OutputDir` | `NULL` | PDF destination. `NULL` writes the report inside `SampleDir`; a missing custom directory is created. |

### Result

Writes a multi-page annotated PDF and invisibly returns its path, resolved source files, selected chromosomes, step size, y limits, and a record of display-only operations.

### Example

```r
ChIP_BrDU_WholeGenome_Plotter(
  SampleDir="/data/analysis/Smc5_60HU",
  Assay="ChIP",
  Alignment="generic",
  StrandMode="collapsed",
  Metric="ratio.ipin.noise",
  Chromosomes=c("chrIII", "chrIV"),
  WindowSizeKb=50,
  PlotStyle="hist",
  y_val=NULL
)
```

<a id="chip_brdu_region_plotter"></a>

## 5. `ChIP_BrDU_Region_Plotter()`

Plots ChIP or BrDU profiles across user-defined coordinates on one chromosome. It accepts one sample or multiple samples stacked with a shared y-axis scale and one common genomic-annotation track.

```r
ChIP_BrDU_Region_Plotter(
  SampleDir,
  Chromosome,
  RegionStart,
  RegionEnd,
  Assay="ChIP",
  Alignment="generic",
  StrandMode="collapsed",
  Metric="ratio.ipin.noise",
  Log2Profile=TRUE,
  SampleLabels=NULL,
  PlotStyle="hist",
  y_val=NULL,
  OutputDir=NULL
)
```

### Arguments

| Argument | Default | Explanation |
|---|---|---|
| `SampleDir` | required | One completed sample directory or a character vector of directories to compare in vertically stacked panels. |
| `Chromosome` | required | One chromosome identifier, such as `"chrIV"`, `"IV"`, or `4`. The requested region must lie within that chromosome. |
| `RegionStart` | required | Non-negative zero-based start coordinate in base pairs. |
| `RegionEnd` | required | End coordinate in base pairs; it must exceed `RegionStart` and not exceed the chromosome length. |
| `Assay` | `"ChIP"` | One assay applied to every sample, or one `"ChIP"`/`"BrDU"` value per `SampleDir`. |
| `Alignment` | `"generic"` | One alignment mode applied to every sample, or one `"generic"`/`"malign"` value per directory. |
| `StrandMode` | `"collapsed"` | Chooses collapsed or separated display for every sample. Separated mode mirrors Crick and ignores `Log2Profile`. |
| `Metric` | `"ratio.ipin.noise"` | One final ratio-table metric shared across the compared samples. |
| `Log2Profile` | `TRUE` | Enables collapsed log2 display. Separated regional profiles always remain untransformed so the mirrored strand convention stays unambiguous. |
| `SampleLabels` | `NULL` | Optional display label for each sample. `NULL` uses the corresponding sample-directory basename. |
| `PlotStyle` | `"hist"` | Selects bar-style `"hist"` or continuous `"lines"` profiles. |
| `y_val` | `NULL` | Positive manual upper limit shared by all samples. Separated mode uses symmetric positive and negative limits. |
| `OutputDir` | `NULL` | PDF destination. For one sample, `NULL` uses that sample directory; for multiple samples, it uses the parent of the first sample. |

### Result

Writes an annotated regional PDF and invisibly returns the sample labels, ratio files, coordinates, common y limits, page count, and display-operation metadata.

### Example

```r
ChIP_BrDU_Region_Plotter(
  SampleDir=c("/data/analysis/WT", "/data/analysis/mutant"),
  Chromosome="chrIV",
  RegionStart=400000,
  RegionEnd=500000,
  Assay="ChIP",
  Alignment="generic",
  StrandMode="collapsed",
  Metric="ratio.ipin.noise",
  Log2Profile=TRUE,
  SampleLabels=c("WT", "mutant"),
  PlotStyle="lines"
)
```

<a id="chip_brdu_rdna_plotter"></a>

## 6. `ChIP_BrDU_rDNA_Plotter()`

Plots one or more completed `mrdna` samples across the exact custom two-repeat rDNA reference. The annotation uses two literal copies of the selected NTS1-containing unit and does not substitute the non-identical native SGD second repeat.

```r
ChIP_BrDU_rDNA_Plotter(
  SampleDir,
  Assay="ChIP",
  StrandMode="collapsed",
  Metric="ratio.ipin.noise",
  Log2Profile=TRUE,
  SampleLabels=NULL,
  PlotStyle="lines",
  y_val=NULL,
  OutputDir=NULL
)
```

### Arguments

| Argument | Default | Explanation |
|---|---|---|
| `SampleDir` | required | One completed `mrdna` sample directory or a vector of such directories. Each must contain `Ratios_ma_rdna`. |
| `Assay` | `"ChIP"` | One assay shared by all samples or one `"ChIP"`/`"BrDU"` value per sample directory. |
| `StrandMode` | `"collapsed"` | Selects the collapsed rDNA table or the Watson/Crick rDNA tables. Separated mode mirrors Crick below zero. |
| `Metric` | `"ratio.ipin.noise"` | One saved rDNA ratio-table metric to display. |
| `Log2Profile` | `TRUE` | Enables log2 display only for collapsed profiles. Separated rDNA profiles remain untransformed. |
| `SampleLabels` | `NULL` | Optional labels corresponding one-to-one with `SampleDir`; directory basenames are used by default. |
| `PlotStyle` | `"lines"` | Selects line or histogram-style presentation. Lines are the default for the compact rDNA reference. |
| `y_val` | `NULL` | Positive manual upper limit shared across samples. In separated mode, the same value is used symmetrically above and below zero. |
| `OutputDir` | `NULL` | PDF destination. One sample defaults to its sample directory; multiple samples default to the parent of the first directory. |

### Result

Writes an rDNA PDF with exact feature tracks and invisibly returns the ratio files, reference and annotation paths, unit length, y limits, and page information. No peak annotations are used.

### Example

```r
ChIP_BrDU_rDNA_Plotter(
  SampleDir=c("/data/analysis/WT_rDNA", "/data/analysis/mutant_rDNA"),
  Assay="ChIP",
  StrandMode="collapsed",
  Metric="ratio.ipin.noise",
  Log2Profile=TRUE,
  SampleLabels=c("WT", "mutant")
)
```

<a id="chip_brdu_peak_enrichment_plotter"></a>

## 7. `ChIP_BrDU_Peak_Enrichment_Plotter()`

Produces the fixed four-page peak-centred report for the five saved primary-analysis peak classes. It summarizes the final ratio tables around the saved peak summits and does not call or reclassify peaks.

```r
ChIP_BrDU_Peak_Enrichment_Plotter(
  SampleDir,
  Assay=c("ChIP", "BrDU"),
  Alignment=c("generic", "malign"),
  StrandMode=c("collapsed", "separated"),
  Log2Profile=FALSE,
  Window=3000,
  OutputDir=NULL,
  y_lim=NULL
)
```

### Arguments

| Argument | Default | Explanation |
|---|---|---|
| `SampleDir` | required | One completed nuclear sample directory containing all five saved peak BED files and the required ratio table or tables. |
| `Assay` | ChIP or BrDU | Selects the assay-specific ratio files and plot titles. |
| `Alignment` | generic or malign | Selects `Peaks`/`Ratios` or `Peaks_ma`/`Ratios_ma`. |
| `StrandMode` | collapsed or separated | Uses one collapsed table or Watson/Crick tables. Separated mode plots Watson positive and mirrored Crick negative. |
| `Log2Profile` | `FALSE` | `FALSE` preserves the saved scale. `TRUE` uses `log2(x)` for collapsed profiles and `log2(1+x)` before strand mirroring for separated profiles. |
| `Window` | `3000` | Positive half-window in base pairs around every saved peak summit. |
| `OutputDir` | `NULL` | PDF destination; `NULL` writes to `SampleDir`. |
| `y_lim` | `NULL` | `NULL` keeps automatic scaling. Use `c(lower, upper)` for one range across all metrics, or a named list such as `list(ip.score=c(0, 300), ratio.ipin.noise=c(0.8, 3))` for selected metrics. The range is shared by the corresponding individual and pairwise panels. |

### Report organization

Page 1 reports peak-class counts. Pages 2 and 3 plot the five cohorts across all four metrics. Page 4 compares Origin/NonOrigin, EarlyOrigin/NonOrigin, Origin/Genomewide, and EarlyOrigin/LateOrigin using clean enrichment.

### Result

Writes a four-page PDF and invisibly returns peak files and counts, profile matrices, metric details, cohort consistency checks, and the plotting-operation record.

### Example

```r
ChIP_BrDU_Peak_Enrichment_Plotter(
  SampleDir="/data/analysis/Smc5_60HU",
  Assay="ChIP",
  Alignment="generic",
  StrandMode="separated",
  Log2Profile=FALSE,
  Window=3000,
  y_lim=NULL
)
```

<a id="chip_brdu_genomic_element_enrichment_plotter"></a>

## 8. `ChIP_BrDU_Genomic_Element_Enrichment_Plotter()`

Creates median average profiles around selected curated genomic features or saved peak cohorts. Each cohort is shown across all four final metrics, with three cohort rows per page and dedicated pairwise pages where applicable.

```r
ChIP_BrDU_Genomic_Element_Enrichment_Plotter(
  SampleDir,
  Assay=c("ChIP", "BrDU"),
  Alignment=c("generic", "malign"),
  StrandMode=c("collapsed", "separated"),
  Log2Profile=FALSE,
  Window=3000,
  OutputDir=NULL,
  Elements=NULL,
  y_lim=NULL
)
```

### Arguments

| Argument | Default | Explanation |
|---|---|---|
| `SampleDir` | required | One completed nuclear sample directory containing the final ratio output and any sample-specific peak cohorts requested in `Elements`. |
| `Assay` | ChIP or BrDU | Selects assay-specific ratio files and panel titles. |
| `Alignment` | generic or malign | Selects standard or multi-alignment nuclear output folders. |
| `StrandMode` | collapsed or separated | Chooses a collapsed average profile or Watson-positive/Crick-negative strand profiles. |
| `Log2Profile` | `FALSE` | `TRUE` uses `log2(x)` in collapsed mode and `log2(1+x)` in separated mode. It changes only the displayed profiles. |
| `Window` | `3000` | Positive half-window in base pairs around each curated midpoint or saved peak summit. |
| `OutputDir` | `NULL` | PDF destination; `NULL` writes to `SampleDir`. |
| `Elements` | `NULL` | `NULL` requests the complete curated-element report. Otherwise supply one or more supported curated or peak selectors without duplicates. |
| `y_lim` | `NULL` | `NULL` keeps automatic scaling. Use `c(lower, upper)` for one range across all metrics, or a named list such as `list(ip.score=c(0, 300), ratio.ipin.noise=c(0.8, 3))` for selected metrics. The range is shared by the corresponding individual and paired panels. |

### Report organization

The report starts with selected-cohort counts and then plots up to three cohorts per page across ChIP/BrDU, assay/input, assay/noise, and Clean panels. Complete Early/Late, CTrans/WTrans, and Convergent/Divergent selections also receive paired comparison rows.

### Result

Writes a multi-page PDF and invisibly returns element sources and counts, anchor diagnostics, median profiles, page layout, and display-operation metadata.

### Example

```r
ChIP_BrDU_Genomic_Element_Enrichment_Plotter(
  SampleDir="/data/analysis/Smc5_60HU",
  Assay="ChIP",
  Alignment="generic",
  StrandMode="collapsed",
  Elements=c("EarlyOrigin", "LateOrigin", "OriginPeaks"),
  Log2Profile=FALSE,
  Window=3000,
  y_lim=NULL
)
```

<a id="chip_brdu_early_late_enrichment_plotter"></a>

## 9. `ChIP_BrDU_Early_Late_Enrichment_Plotter()`

Produces the focused single-assay Early-versus-Late origin report. It combines individual and paired average profiles with a fourth page of side-by-side Early/Late boxplots and statistical p-values.

```r
ChIP_BrDU_Early_Late_Enrichment_Plotter(
  SampleDir,
  Assay=c("ChIP", "BrDU"),
  Alignment=c("generic", "malign"),
  StrandMode=c("collapsed", "separated"),
  Log2Profile=FALSE,
  Window=3000,
  OutputDir=NULL,
  y_lim=NULL
)
```

### Arguments

| Argument | Default | Explanation |
|---|---|---|
| `SampleDir` | required | One completed nuclear sample directory. The report reads the processed Early and Late origin support files and the sample's final ratio tables. |
| `Assay` | ChIP or BrDU | Selects the assay-specific ratio files and panel labels. |
| `Alignment` | generic or malign | Selects the corresponding nuclear ratio-output folder. |
| `StrandMode` | collapsed or separated | Controls the average-profile pages. Page 4 always uses the saved collapsed table because the statistical distributions are strand-collapsed. |
| `Log2Profile` | `FALSE` | Enables display transformation where supported. For separated average profiles it uses `log2(1+x)` before Crick mirroring; page-4 boxes use the corresponding collapsed display scale. |
| `Window` | `3000` | Positive half-window in base pairs around each Early or Late origin midpoint for both profiles and per-origin boxplot summaries. |
| `OutputDir` | `NULL` | PDF destination; `NULL` writes to `SampleDir`. |
| `y_lim` | `NULL` | `NULL` keeps automatic scaling. Use `c(lower, upper)` for one range across all four metrics, or a named list such as `list(ip.score=c(0, 300), ratio.ipin.noise=c(0.8, 3))` for selected metrics. The range also applies to the corresponding paired profile and page-4 boxplot panel. |

### Statistical page

Each origin contributes the arithmetic mean of the saved metric values within the selected window. Every metric panel reports a two-sided Wilcoxon rank-sum p-value and its BH adjustment across the four metrics. Exact coordinates present in both origin lists remain visible but are excluded from the tests; outlier symbols are hidden only graphically.

### Result

Writes a four-page PDF and invisibly returns the profiles, origin counts, boxplot scores and summaries, y limits, raw and adjusted statistical results, and shared-coordinate exclusions.

### Example

```r
ChIP_BrDU_Early_Late_Enrichment_Plotter(
  SampleDir="/data/analysis/Smc5_60HU",
  Assay="ChIP",
  Alignment="generic",
  StrandMode="collapsed",
  Log2Profile=FALSE,
  Window=3000,
  y_lim=NULL
)
```

<a id="chip_brdu_genomic_element_boxplotter"></a>

## 10. `ChIP_BrDU_Genomic_Element_Boxplotter()`

Creates strand-collapsed per-element enrichment distributions for selected curated or peak cohorts. Standard pages keep cohorts separate by metric, while a final page places all selected cohorts side by side for one chosen comparison metric.

```r
ChIP_BrDU_Genomic_Element_Boxplotter(
  SampleDir,
  Assay=c("ChIP", "BrDU"),
  Alignment=c("generic", "malign"),
  Elements=c("EarlyOrigin", "LateOrigin"),
  Metric="all",
  Window=500,
  Log2Values=TRUE,
  OutputDir=NULL,
  ComparisonMetric="ratio.ipin.noise"
)
```

### Arguments

| Argument | Default | Explanation |
|---|---|---|
| `SampleDir` | required | One completed nuclear sample directory containing the collapsed final ratio table and any requested saved peak cohorts. |
| `Assay` | ChIP or BrDU | Selects the assay-specific collapsed ratio file and report labels. |
| `Alignment` | generic or malign | Selects the corresponding nuclear ratio and peak folders. |
| `Elements` | Early and Late origins | One or more unique curated or peak selectors. Each selected record is one statistical unit in its cohort. |
| `Metric` | `"all"` | Controls the regular element-specific pages. Use `"all"`, one metric, or a vector of unique final metric names. |
| `Window` | `500` | Non-negative half-window in base pairs used to calculate each element's arithmetic mean. `0` uses the ratio interval nearest the feature centre. |
| `Log2Values` | `TRUE` | `TRUE` displays `log2(1+x)` for coverage and `log2(x)` for positive ratio values. `FALSE` preserves the untransformed saved scale. |
| `OutputDir` | `NULL` | PDF destination; `NULL` writes to `SampleDir`. |
| `ComparisonMetric` | `"ratio.ipin.noise"` | Chooses the single metric on the final all-cohort side-by-side page. It is independent of `Metric` and may be `ip.score`, `ratio.ipin`, `ratio.ipnoise`, or `ratio.ipin.noise`. |

### Statistical comparison

With two cohorts, the final page reports a two-sided Wilcoxon rank-sum test. With three or more cohorts, it reports a global Kruskal-Wallis test and BH-adjusted pairwise two-sided Wilcoxon tests. Pairwise values are printed in the PDF for up to six cohorts and remain available in the returned `comparison_statistics` table when more cohorts are selected.

Coordinates shared between selected cohorts remain in the displayed boxes but are excluded from between-cohort tests. Individual points and outlier symbols are hidden; the underlying values are retained.

### Result

Writes a multi-page PDF and invisibly returns per-element scores, display values, box summaries, shared coordinates, statistical results, y limits, and page-layout metadata.

### Example

```r
ChIP_BrDU_Genomic_Element_Boxplotter(
  SampleDir="/data/analysis/Smc5_60HU",
  Assay="ChIP",
  Alignment="generic",
  Elements=c("EarlyOrigin", "LateOrigin", "OriginPeaks"),
  Metric="all",
  Window=500,
  Log2Values=TRUE,
  ComparisonMetric="ratio.ipin.noise"
)
```

<a id="chip_brdu_genomic_element_heatmap_plotter"></a>

## 11. `ChIP_BrDU_Genomic_Element_Heatmap_Plotter()`

Creates publication-oriented strand-collapsed heatmaps for one or more selected curated or peak cohorts. Each cohort occupies one page, with selected metrics arranged horizontally.

```r
ChIP_BrDU_Genomic_Element_Heatmap_Plotter(
  SampleDir,
  Assay=c("ChIP", "BrDU"),
  Alignment=c("generic", "malign"),
  Elements=c("EarlyOrigin", "LateOrigin"),
  Metric="all",
  Window=3000,
  Log2Values=TRUE,
  OrderBy="ratio.ipin.noise",
  OutputDir=NULL,
  x_lim=NULL,
  z_lim=NULL
)
```

### Arguments

| Argument | Default | Explanation |
|---|---|---|
| `SampleDir` | required | One completed nuclear sample directory containing the collapsed ratio table and any requested saved peak cohorts. |
| `Assay` | ChIP or BrDU | Selects the assay-specific collapsed ratio file and titles. |
| `Alignment` | generic or malign | Selects standard or multi-alignment nuclear output folders. |
| `Elements` | Early and Late origins | One or more unique curated or peak cohorts. A separate page is created for each cohort. |
| `Metric` | `"all"` | Selects `"all"`, one metric, or a vector of unique metrics to arrange in one horizontal row. |
| `Window` | `3000` | Positive half-window in base pairs around each feature midpoint or peak summit. |
| `Log2Values` | `TRUE` | Uses `log2(1+x)` for coverage and `log2(x)` for positive ratio values when `TRUE`; raw values are retained when `FALSE`. |
| `OrderBy` | `"ratio.ipin.noise"` | Orders rows by decreasing mean of one final metric across the complete extracted `Window`. Use `"genomic"` to retain nuclear chromosome and coordinate order. |
| `OutputDir` | `NULL` | PDF destination; `NULL` writes to `SampleDir`. |
| `x_lim` | `NULL` | Optional symmetric plotted half-width in base pairs. It must not exceed `Window` and must be divisible by the saved sliding-window step. It crops only the plotted view; extraction and row ordering still use the complete `Window`. |
| `z_lim` | `NULL` | Optional positive display-saturation limit. One value applies to every selected metric; an unnamed vector follows `Metric` order; a named vector can override selected metrics, for example `c(ip.score=8, ratio.ipin.noise=2)`. Log2 ratio metrics use symmetric `-z_lim` to `+z_lim`; other displays use `0` to `z_lim`. |

### Display behavior

Heatmaps use no spline smoothing, row normalization, or row clustering. They reproduce the older Loli-edited enrichment heatmap palette exactly: 100 colors from viridis option `"C"` (plasma), for both ChIP and BrDU. When `z_lim=NULL`, the second and ninety-eighth percentiles provide display-only color saturation; supplied limits replace that automatic scale. Each metric keeps one common color scale across all selected cohort pages. `x_lim` and `z_lim` affect only presentation, and returned matrices retain the full extracted values.

### Result

Writes one PDF page per cohort and invisibly returns raw and displayed matrices, row order and metadata, color limits, element sources, and page dimensions.

### Example

```r
ChIP_BrDU_Genomic_Element_Heatmap_Plotter(
  SampleDir="/data/analysis/Smc5_60HU",
  Assay="ChIP",
  Alignment="generic",
  Elements=c("EarlyOrigin", "LateOrigin", "OriginPeaks"),
  Metric="all",
  Window=3000,
  Log2Values=TRUE,
  OrderBy="ratio.ipin.noise",
  x_lim=2000,
  z_lim=c(
    ip.score=8,
    ratio.ipin=2,
    ratio.ipnoise=3,
    ratio.ipin.noise=2
  )
)
```

<a id="chip_brdu_region_comparison_plotter"></a>

## 12. `ChIP_BrDU_Region_Comparison_Plotter()`

Overlays one ChIP sample and one BrDU sample across defined coordinates using two baseline-aligned y-axes. ChIP is a solid line on the left axis and BrDU is a dotted line on the right axis.

```r
ChIP_BrDU_Region_Comparison_Plotter(
  ChIPSampleDir,
  BrDUSampleDir,
  Chromosome,
  RegionStart,
  RegionEnd,
  Alignment=c("generic", "malign"),
  Metric=c("ratio.ipin.noise", "ratio.ipin", "ratio.ipnoise", "ip.score"),
  Log2Profile=FALSE,
  y_val_chip=NULL,
  y_val_brdu=NULL,
  OutputDir=NULL
)
```

### Arguments

| Argument | Default | Explanation |
|---|---|---|
| `ChIPSampleDir` | required | Completed ChIP sample directory containing the collapsed ratio table for the selected alignment. |
| `BrDUSampleDir` | required | Completed BrDU sample directory containing a coordinate-compatible collapsed ratio table. |
| `Chromosome` | required | One chromosome identifier such as `"chrIV"`, `"IV"`, or `4`. |
| `RegionStart` | required | Non-negative zero-based start coordinate in base pairs. |
| `RegionEnd` | required | End coordinate in base pairs; it must exceed the start and remain within the chromosome. |
| `Alignment` | generic or malign | One common alignment mode for both samples. Their regional coordinate grids must match exactly. |
| `Metric` | `"ratio.ipin.noise"` first | One final metric to overlay for both assays. |
| `Log2Profile` | `FALSE` | `TRUE` uses `log2(1+x)` for coverage and `log2(x)` for positive ratios; `FALSE` preserves the original values. |
| `y_val_chip` | `NULL` | Optional ChIP upper limit on the left axis. It must exceed the displayed neutral baseline; the lower limit remains internally calculated. |
| `y_val_brdu` | `NULL` | Optional BrDU upper limit on the right axis. It is resolved independently and then aligned to the ChIP baseline. |
| `OutputDir` | `NULL` | PDF destination. A shared sample parent is preferred automatically; otherwise the ChIP sample directory is used. |

### Result

Writes one annotated dual-axis regional PDF and invisibly returns both ratio files, coordinate compatibility checks, y-limit and clipping tables, baseline information, and annotation details. Peaks are intentionally not displayed.

### Example

```r
ChIP_BrDU_Region_Comparison_Plotter(
  ChIPSampleDir="/data/analysis/Smc5_ChIP",
  BrDUSampleDir="/data/analysis/Smc5_BrDU",
  Chromosome="chrIV",
  RegionStart=400000,
  RegionEnd=500000,
  Alignment="generic",
  Metric="ratio.ipin.noise",
  Log2Profile=FALSE,
  y_val_chip=NULL,
  y_val_brdu=NULL
)
```

<a id="chip_brdu_enrichment_comparison_plotter"></a>

## 13. `ChIP_BrDU_Enrichment_Comparison_Plotter()`

Overlays element- or peak-centred ChIP and BrDU median profiles for an explicit assay pair. Each selected cohort occupies one row, with ChIP on the left axis and BrDU on the right axis.

```r
ChIP_BrDU_Enrichment_Comparison_Plotter(
  ChIPSampleDir,
  BrDUSampleDir,
  Alignment=c("generic", "malign"),
  Elements=c("EarlyOrigin", "LateOrigin"),
  Metric="all",
  Window=3000,
  Log2Profile=FALSE,
  y_val_chip=NULL,
  y_val_brdu=NULL,
  OutputDir=NULL,
  PeakSource=c("ChIP", "BrDU")
)
```

### Arguments

| Argument | Default | Explanation |
|---|---|---|
| `ChIPSampleDir` | required | Completed ChIP sample directory supplying the collapsed ChIP ratio table. |
| `BrDUSampleDir` | required | Completed BrDU sample directory supplying the collapsed BrDU ratio table. Its coordinate grid must match the ChIP table. |
| `Alignment` | generic or malign | One common nuclear alignment mode for both assays. |
| `Elements` | Early and Late origins | One or more curated or peak selectors. Every selected cohort is used as one common coordinate set for both assays. |
| `Metric` | `"all"` | Selects all four metrics, one metric, or a vector of unique final metrics. Selected metrics form the panel columns. |
| `Window` | `3000` | Positive half-window in base pairs around each curated midpoint or selected peak summit. |
| `Log2Profile` | `FALSE` | `TRUE` uses `log2(1+x)` for coverage and `log2(x)` for positive ratios. The same display rule is applied to both assays. |
| `y_val_chip` | `NULL` | Optional ChIP upper limit: one value for every metric, one value per selected metric, or a named vector keyed by selected metric. |
| `y_val_brdu` | `NULL` | Optional BrDU upper limit with the same scalar, ordered-vector, or named-vector forms as `y_val_chip`. |
| `OutputDir` | `NULL` | PDF destination. A common parent directory is used when available; otherwise the ChIP sample directory is used. |
| `PeakSource` | ChIP or BrDU | When any `*Peaks` selector is requested, chooses the one assay whose saved peak coordinates are applied to both ratio tables. It has no effect for curated-only selections. |

### Why `PeakSource` is necessary

ChIP and BrDU can have different independently called peaks. Using one explicit source ensures that both signals are evaluated at exactly the same loci instead of comparing two different coordinate cohorts.

### Result

Writes a multi-page dual-axis PDF and invisibly returns both ratio sources, paired-coordinate validation, element or peak anchors, profiles, y-limit tables, baselines, and selected peak-source information.

### Example

```r
ChIP_BrDU_Enrichment_Comparison_Plotter(
  ChIPSampleDir="/data/analysis/Smc5_ChIP",
  BrDUSampleDir="/data/analysis/Smc5_BrDU",
  Alignment="generic",
  Elements=c("EarlyOrigin", "LateOrigin", "OriginPeaks"),
  Metric="all",
  Window=3000,
  Log2Profile=FALSE,
  y_val_chip=NULL,
  y_val_brdu=NULL,
  PeakSource="ChIP"
)
```

<a id="chip_brdu_timeseries_analysis"></a>

## 14. `ChIP_BrDU_TimeSeries_Analysis()`

Coordinates two to ten completed primary-analysis samples from an ordered ChIP or BrDU time course. It builds one common peak mask and one deterministic background grid, estimates each sample's background on those identical coordinates, and writes new coordinated ratios without changing the primary sample folders.

```r
ChIP_BrDU_TimeSeries_Analysis(
  SampleDirs,
  TimePoints,
  Assay=c("ChIP", "BrDU"),
  Alignment=c("generic", "malign"),
  SeriesName="TimeSeries",
  PeakSet=c("union", "reference"),
  ReferenceTimePoint=NULL,
  CenterSets=c("EarlyOrigin", "LateOrigin", "AllOrigins"),
  Metric=c("ratio.ipin.noise", "ratio.ipin", "ratio.ipnoise", "ip.score"),
  Window=3000,
  WindowSizeKb=50,
  Log2Values=FALSE,
  PlotStyle=c("lines", "hist"),
  HeatmapOrderBy="last",
  y_val=NULL,
  OutputDir=NULL
)
```

### Arguments

| Argument | Default | Explanation |
|---|---|---|
| `SampleDirs` | required | Ordered vector of two to ten completed primary-analysis sample directories. Every sample must use the same assay, alignment mode, reference and sliding-window coordinate grid. |
| `TimePoints` | required | Unique labels in biological order, one per sample directory. This order controls the colour gradient and all time-series panels. |
| `Assay` | ChIP or BrDU | Selects the assay coverage, ratio and peak filenames in every completed sample. |
| `Alignment` | generic or malign | Selects the standard or multi-alignment nuclear output folders. Dedicated `mrdna` output is outside this function. |
| `SeriesName` | `"TimeSeries"` | Descriptive prefix used for the series folder, tables, masks and PDFs. |
| `PeakSet` | union or reference | `"union"` merges overlapping genome-wide peaks from every time point. `"reference"` uses the saved peaks from one selected time point. |
| `ReferenceTimePoint` | `NULL` | Exact time-point label or one-based numeric index required by `PeakSet="reference"`; ignored for a union. |
| `CenterSets` | Early, Late and All origins | One or more shared centre cohorts for average profiles and heatmaps. Supported values are `EarlyOrigin`, `LateOrigin`, `AllOrigins` and the five calculated `*Peaks` selectors. |
| `Metric` | `"ratio.ipin.noise"` first | One coordinated metric used by the genome-wide profile, average profiles and heatmaps. |
| `Window` | `3000` | Half-window in base pairs around every origin midpoint or common peak summit. It must be divisible by the saved sliding-window step. |
| `WindowSizeKb` | `50` | Genomic span in kilobases represented by one stacked genome-wide PDF page. |
| `Log2Values` | `FALSE` | Applies `log2(1+x)` to coverage or `log2(x)` to positive ratio values for display and centre summaries. Coordinated BED values remain untransformed. |
| `PlotStyle` | `"lines"` | Rendering for the stacked genome-wide PDF only. Use `"lines"` for smoothed curves or `"hist"` for vertical histogram bars. Average profiles always remain smoothed line plots. |
| `HeatmapOrderBy` | `"last"` | Shared heatmap row order. `"last"` sorts by decreasing window-mean signal at the final supplied time point. Use an exact `TimePoints` label to sort by that time point, `"peak_time"` for activation-time grouping, or `"genomic"` for chromosome-coordinate order. |
| `y_val` | `NULL` | Optional common upper plotting limit for genome-wide and average-profile panels. `NULL` uses robust automatic scaling. |
| `OutputDir` | `NULL` | Complete time-series output directory. By default, a `SeriesName_TimeSeries` folder is created beside the first sample directory. |

### Fixed background contract

The public call intentionally has no external BED or low-mappability-mask argument. The current implementation:

- buffers the common genome-wide peaks by 600 bp;
- excludes `chrM` from background training;
- excludes chrXII coordinates 451,417–469,691, corresponding to the two represented rDNA units in the bundled S288C reference;
- excludes the terminal 15 kb at both ends of every nuclear chromosome;
- creates non-overlapping, absolute 2-kb candidate chunks and uses only coverage windows fully contained by a chunk;
- retains only chunks with positive median raw Input coverage at every time point; and
- fits the same log-scale chromosome-position background model used conceptually by primary analysis, but on the fixed deterministic chunks instead of independently resampled coordinates.

Each sample keeps its own assay and Input background magnitude; only the genomic coordinates used to estimate those backgrounds are shared. The function preserves primary `ip.score`, `in.score`, `ratio.ipin` and, for generic alignment, `pvalue`. It recalculates `ip.noise`, `in.noise`, `ratio.ipnoise` and `ratio.ipin.noise` in new tables.

The QC PDF reports the number of fixed eligible 2-kb chunks per chromosome and the median raw assay and Input coverage over those same coordinates at every time point. Input is the common eligibility gate, while both assay and Input backgrounds are estimated and therefore both are now shown.

### Centre sets and reports

`AllOrigins` reads every confirmed ARS coordinate from the bundled oriDB-derived list and anchors profiles at the annotated origin midpoint, whether or not the sample has a called peak. `OriginPeaks` instead contains only calculated peaks classified as origin-associated at one or more selected time points and anchors profiles at their peak summits. The two reports are therefore expected to look similar but need not contain the same loci or alignment centres.

The terminal 15-kb mask is used only for background training. Telomere-proximal nuclear origins and peaks remain in centred tables, average profiles and heatmaps. When a requested flank extends beyond a chromosome end, only the unavailable flank is recorded as missing. `chrM` and rDNA centres remain excluded.

Average profiles always use smoothed lines with one chronological viridis gradient. For the stacked genome-wide PDF, `PlotStyle="lines"` draws smoothed curves and `PlotStyle="hist"` draws vertical histogram bars. Heatmaps keep the same coordinates, row order and colour limits in every time-point panel. By default, rows are sorted by decreasing final-time-point window-mean signal; `HeatmapOrderBy` can select another time point, activation-time grouping or genomic order. Values beyond the shared colour quantiles are saturated at the palette limits rather than rendered as missing. Series containing seven to ten samples wrap the heatmap panels into two rows of at most five time points. The genome-wide PDF uses one coordinate window per page, vertically stacks every time point with one shared y-axis, and places one common genomic-feature track below the stack.

### Output organization

```text
SeriesName_TimeSeries/
├── Analysis_Manifest.tsv
├── Peaks/
│   ├── common peak BED files
│   ├── background exclusion mask
│   └── fixed eligible background chunks
├── Ratios/
│   ├── one coordinated ratio BED per time point
│   ├── background QC table
│   ├── average-profile table
│   └── centre-by-time summary matrix
└── Plots/
    ├── stacked genome-wide PDF
    ├── average-profile PDF
    ├── heatmap PDF
    └── background-QC PDF
```

There are no heatmap-, profile-, or time-point-specific subfolders within these modality folders.

### Interpretation

The common coordinate grid makes relative changes and redistribution across the series more comparable. It does not provide absolute genome-wide occupancy normalization. In particular, a licensing or replication time course without spike-in material must be described as relative enrichment rather than a measurement of total chromatin-bound protein.

The current version is strand-collapsed and descriptive. It has no biological-replicate model, uncertainty interval, IDR analysis or external custom-coordinate input.

### Example

```r
ChIP_BrDU_TimeSeries_Analysis(
  SampleDirs=c(
    "/data/MCM/G1",
    "/data/MCM/10min",
    "/data/MCM/20min",
    "/data/MCM/30min"
  ),
  TimePoints=c("G1", "10 min", "20 min", "30 min"),
  Assay="ChIP",
  Alignment="generic",
  SeriesName="MCM_Licensing",
  PeakSet="union",
  CenterSets=c("EarlyOrigin", "LateOrigin", "AllOrigins", "OriginPeaks"),
  Metric="ratio.ipin.noise",
  Window=3000,
  WindowSizeKb=50,
  Log2Values=FALSE,
  PlotStyle="lines",
  HeatmapOrderBy="last",
  y_val=NULL,
  OutputDir="/data/MCM/MCM_Licensing_TimeSeries"
)
```

<a id="recommended-workflow"></a>

## Recommended workflow

For a new sample:

1. Confirm the bundle with `ChIP_BrDU_Project_Paths(check=TRUE)`.
2. Use `ChIP_BrDU_Complete_Analysis()` for a standard end-to-end run, or `ChIP_BrDU_Primary_Analysis()` when downstream functions will be selected manually.
3. Use the whole-genome and focused Early/Late reports for experiment-specific review.
4. Use regional, rDNA, average-profile, boxplot, and heatmap functions to build targeted figures from the final saved ratio tables.
5. Use `ChIP_BrDU_TimeSeries_Analysis()` after two to ten compatible primary runs when the experiment has an ordered time course.
6. Use the two comparison functions only when an explicit ChIP–BrDU pair is biologically appropriate.

The example calls in `Run_ChIPseq_BrDUseq_Project.R` remain the shortest laboratory interface. This vignette is the detailed reference to consult when changing an argument or interpreting a generated report.
