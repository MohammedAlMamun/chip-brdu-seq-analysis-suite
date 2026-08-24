# Function reference

## Entry points

| Function | Purpose |
|---|---|
| `ChIP_BrDU_Project_Paths()` | Resolves and validates the script-relative support folder. |
| `ChIP_BrDU_Primary_Analysis()` | Runs primary ChIP or BrDU processing for `generic`, `malign` or `mrdna`. |
| `ChIP_BrDU_Complete_Analysis()` | Runs primary analysis and the standard downstream report suite, recording a concise manifest. |

## Profile and enrichment reports

| Function | Samples | Strand modes | Main purpose |
|---|---:|---|---|
| `ChIP_BrDU_WholeGenome_Plotter()` | 1 | collapsed, separated | Whole-chromosome profiles with genomic annotations; collapsed mode can display saved peaks. |
| `ChIP_BrDU_Region_Plotter()` | 1 or more | collapsed, separated | Profiles over user-supplied chromosome coordinates. |
| `ChIP_BrDU_rDNA_Plotter()` | 1 or more | collapsed, separated | Profiles and exact feature annotations over the custom two-repeat rDNA reference. |
| `ChIP_BrDU_Peak_Enrichment_Plotter()` | 1 | collapsed, separated | Average profiles for five saved peak classes. |
| `ChIP_BrDU_Genomic_Element_Enrichment_Plotter()` | 1 | collapsed, separated | Average profiles for curated features or saved peak classes. |
| `ChIP_BrDU_Early_Late_Enrichment_Plotter()` | 1 | collapsed, separated | Focused Early/Late report with individual profiles, paired profiles and comparative boxplots with Wilcoxon p-values. |
| `ChIP_BrDU_Genomic_Element_Boxplotter()` | 1 | collapsed | Element-centred distributions plus a final single-metric statistical comparison of all selected cohorts. |
| `ChIP_BrDU_Genomic_Element_Heatmap_Plotter()` | 1 | collapsed | Publication-oriented heatmaps ordered by a selected metric. |

## Direct ChIP–BrDU comparisons

| Function | Purpose |
|---|---|
| `ChIP_BrDU_Region_Comparison_Plotter()` | Overlays collapsed ChIP and BrDU signals across defined coordinates, using left and right y-axes. |
| `ChIP_BrDU_Enrichment_Comparison_Plotter()` | Overlays element- or peak-centred ChIP and BrDU enrichment, using separate y-axes and one common coordinate cohort. |

For peak-based paired comparisons, `PeakSource="ChIP"` or `PeakSource="BrDU"` determines which assay supplies the common peak coordinates.

## Standard selectors

Assay:

```r
Assay=c("ChIP", "BrDU")
```

Nuclear alignment:

```r
Alignment=c("generic", "malign")
```

Strand display:

```r
StrandMode=c("collapsed", "separated")
```

Metrics:

```r
c("ip.score", "ratio.ipin", "ratio.ipnoise", "ratio.ipin.noise")
```

The boxplotter's `Metric` argument controls the standard four-panel element pages. Its independent `ComparisonMetric` argument controls the final side-by-side comparison page and defaults to `"ratio.ipin.noise"` (Clean).

Curated element selectors:

```r
c(
  "ARS", "EarlyOrigin", "LateOrigin", "TER", "Ty", "tRNA",
  "Centromere", "Convergent", "Divergent", "CTrans", "WTrans"
)
```

Calculated peak selectors:

```r
c(
  "GenomewidePeaks", "NonOriginPeaks", "OriginPeaks",
  "EarlyOriginPeaks", "LateOriginPeaks"
)
```

## Interpretation notes

- Watson is plotted in `brown3` above zero and Crick in `cornflowerblue` below zero in separated profiles.
- Peak-based coloring and peak annotation are limited to strand-collapsed whole-genome plots because the peaks originate from collapsed analysis.
- Strand-separated whole-genome profiles are untransformed.
- Ratio metrics use a raw neutral baseline of 1; after log2 transformation their neutral baseline is 0.
- Average profiles apply spline smoothing only while drawing the curves.
- Two boxplot cohorts are compared using a two-sided Wilcoxon rank-sum test. Three or more cohorts use a global Kruskal-Wallis test and BH-adjusted pairwise two-sided Wilcoxon tests.
- Coordinates shared between selected cohorts remain visible in the boxplots but are excluded from between-cohort statistical tests.
- ORFs and rDNA are excluded as average-profile cohorts; their architectures require dedicated treatment.
- Mitochondrial chromosome `chrM` is omitted from element-centred analyses.
