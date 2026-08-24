###############################################################################
## BLOCK 1 — LOAD THE MAIN SCRIPT
## Run this line first, then execute only the analysis call you need.
###############################################################################
local({frame_files <- vapply(sys.frames(), function(frame) if(is.null(frame$ofile) || length(frame$ofile) == 0L) NA_character_ else as.character(frame$ofile[[1]]), character(1)); command_file <- sub("^--file=", "", grep("^--file=", commandArgs(trailingOnly=FALSE), value=TRUE)); editor_file <- if(requireNamespace("rstudioapi", quietly=TRUE) && rstudioapi::isAvailable()) tryCatch(rstudioapi::getActiveDocumentContext()$path, error=function(error) NA_character_) else NA_character_; candidates <- c(editor_file, rev(frame_files), command_file); candidates <- candidates[!is.na(candidates) & nzchar(candidates)]; main_candidates <- c(file.path(dirname(candidates), "ChIPseq_BrDUseq_Project.R"), file.path(getwd(), "ChIPseq_BrDUseq_Project.R")); main_file <- main_candidates[file.exists(main_candidates)]; if(length(main_file) == 0L) stop("Could not locate ChIPseq_BrDUseq_Project.R. Open this run script in RStudio and use Source, or set the working directory to the shared bundle folder.", call.=FALSE); source(normalizePath(main_file[[1]], winslash="/", mustWork=TRUE))})


###############################################################################
## BLOCK 2 — COMPLETE ANALYSIS: FASTQs TO THE STANDARD REPORT SET
## Edit paths and settings, then run. Keep Regions=NULL unless needed.
## Elements controls boxplots/heatmaps; optional ProfileElements controls
## average profiles. Peak selectors are listed in Blocks 3 and 4.
###############################################################################
ChIP_BrDU_Complete_Analysis( Input_R1="/full/path/to/input_R1.fastq.gz",
                             Input_R2="/full/path/to/input_R2.fastq.gz",
                             Assay_R1="/full/path/to/assay_R1.fastq.gz",
                             Assay_R2="/full/path/to/assay_R2.fastq.gz",
                             Assay="ChIP",
                             Alignment="generic",
                             ExpTitle="SampleName",
                             Directory="/full/path/to/ChIP_results",
                             StrandModes=c("collapsed", "separated"),
                             Elements=c("EarlyOrigin", "LateOrigin"),
                             Regions=NULL )


###############################################################################
## BLOCK 3 — INDIVIDUAL ChIP ANALYSES
## Set the sample directory/alignment, then run the desired call.
## Window is bp; WindowSizeKb is kb; y_val=NULL uses automatic axes.
## Peak elements: GenomewidePeaks, NonOriginPeaks, OriginPeaks,
## EarlyOriginPeaks, LateOriginPeaks.
###############################################################################
CHIP_SAMPLE_DIR <- "/full/path/to/ChIP_results/SampleName"
CHIP_ALIGNMENT <- "generic"

ChIP_BrDU_Primary_Analysis( Input_R1="/full/path/to/input_R1.fastq.gz",
                            Input_R2="/full/path/to/input_R2.fastq.gz",
                            Assay_R1="/full/path/to/chip_R1.fastq.gz",
                            Assay_R2="/full/path/to/chip_R2.fastq.gz",
                            Assay="ChIP",
                            Alignment=CHIP_ALIGNMENT,
                            ExpTitle="SampleName",
                            Directory="/full/path/to/ChIP_results" )

ChIP_BrDU_WholeGenome_Plotter( SampleDir=CHIP_SAMPLE_DIR,
                               Assay="ChIP",
                               Alignment=CHIP_ALIGNMENT,
                               StrandMode="collapsed",
                               Metric="ratio.ipin.noise",
                               Chromosomes="all",
                               WindowSizeKb=50,
                               PlotStyle="hist",
                               y_val=NULL )

ChIP_BrDU_Region_Plotter( SampleDir=CHIP_SAMPLE_DIR,
                          Chromosome="chrIV",
                          RegionStart=400000,
                          RegionEnd=500000,
                          Assay="ChIP",
                          Alignment=CHIP_ALIGNMENT,
                          StrandMode="collapsed",
                          Metric="ratio.ipin.noise",
                          Log2Profile=TRUE,
                          PlotStyle="hist",
                          y_val=NULL )

## Requires completed Alignment="mrdna" primary-analysis output.
ChIP_BrDU_rDNA_Plotter( SampleDir=CHIP_SAMPLE_DIR,
                        Assay="ChIP",
                        StrandMode="collapsed",
                        Metric="ratio.ipin.noise",
                        Log2Profile=TRUE,
                        PlotStyle="lines",
                        y_val=NULL )

ChIP_BrDU_Peak_Enrichment_Plotter( SampleDir=CHIP_SAMPLE_DIR,
                                   Assay="ChIP",
                                   Alignment=CHIP_ALIGNMENT,
                                   StrandMode="collapsed",
                                   Log2Profile=FALSE,
                                   Window=3000 )

ChIP_BrDU_Genomic_Element_Enrichment_Plotter( SampleDir=CHIP_SAMPLE_DIR,
                                              Assay="ChIP",
                                              Alignment=CHIP_ALIGNMENT,
                                              StrandMode="collapsed",
                                              Elements=NULL,
                                              Log2Profile=FALSE,
                                              Window=3000 )

ChIP_BrDU_Early_Late_Enrichment_Plotter( SampleDir=CHIP_SAMPLE_DIR,
                                         Assay="ChIP",
                                         Alignment=CHIP_ALIGNMENT,
                                         StrandMode="collapsed",
                                         Log2Profile=FALSE,
                                         Window=3000 )

ChIP_BrDU_Genomic_Element_Boxplotter( SampleDir=CHIP_SAMPLE_DIR,
                                      Assay="ChIP",
                                      Alignment=CHIP_ALIGNMENT,
                                      Elements=c("EarlyOrigin", "LateOrigin"),
                                      Metric="all",
                                      Window=500,
                                      Log2Values=TRUE,
                                      ComparisonMetric="ratio.ipin.noise" )

ChIP_BrDU_Genomic_Element_Heatmap_Plotter( SampleDir=CHIP_SAMPLE_DIR,
                                           Assay="ChIP",
                                           Alignment=CHIP_ALIGNMENT,
                                           Elements=c("EarlyOrigin", "LateOrigin"),
                                           Metric="all",
                                           Window=3000,
                                           Log2Values=TRUE,
                                           OrderBy="ratio.ipin.noise" )


###############################################################################
## BLOCK 4 — INDIVIDUAL BrDU ANALYSES
## Set the sample directory/alignment, then run the desired call.
## Window is bp; WindowSizeKb is kb; y_val=NULL uses automatic axes.
## Peak elements: GenomewidePeaks, NonOriginPeaks, OriginPeaks,
## EarlyOriginPeaks, LateOriginPeaks.
###############################################################################
BRDU_SAMPLE_DIR <- "/full/path/to/BrDU_results/SampleName"
BRDU_ALIGNMENT <- "generic"

ChIP_BrDU_Primary_Analysis( Input_R1="/full/path/to/input_R1.fastq.gz",
                            Input_R2="/full/path/to/input_R2.fastq.gz",
                            Assay_R1="/full/path/to/brdu_R1.fastq.gz",
                            Assay_R2="/full/path/to/brdu_R2.fastq.gz",
                            Assay="BrDU",
                            Alignment=BRDU_ALIGNMENT,
                            ExpTitle="SampleName",
                            Directory="/full/path/to/BrDU_results" )

ChIP_BrDU_WholeGenome_Plotter( SampleDir=BRDU_SAMPLE_DIR,
                               Assay="BrDU",
                               Alignment=BRDU_ALIGNMENT,
                               StrandMode="collapsed",
                               Metric="ratio.ipin.noise",
                               Chromosomes="all",
                               WindowSizeKb=50,
                               PlotStyle="hist",
                               y_val=NULL )

ChIP_BrDU_Region_Plotter( SampleDir=BRDU_SAMPLE_DIR,
                          Chromosome="chrIV",
                          RegionStart=400000,
                          RegionEnd=500000,
                          Assay="BrDU",
                          Alignment=BRDU_ALIGNMENT,
                          StrandMode="collapsed",
                          Metric="ratio.ipin.noise",
                          Log2Profile=TRUE,
                          PlotStyle="hist",
                          y_val=NULL )

## Requires completed Alignment="mrdna" primary-analysis output.
ChIP_BrDU_rDNA_Plotter( SampleDir=BRDU_SAMPLE_DIR,
                        Assay="BrDU",
                        StrandMode="collapsed",
                        Metric="ratio.ipin.noise",
                        Log2Profile=TRUE,
                        PlotStyle="lines",
                        y_val=NULL )

ChIP_BrDU_Peak_Enrichment_Plotter( SampleDir=BRDU_SAMPLE_DIR,
                                   Assay="BrDU",
                                   Alignment=BRDU_ALIGNMENT,
                                   StrandMode="collapsed",
                                   Log2Profile=FALSE,
                                   Window=3000 )

ChIP_BrDU_Genomic_Element_Enrichment_Plotter( SampleDir=BRDU_SAMPLE_DIR,
                                              Assay="BrDU",
                                              Alignment=BRDU_ALIGNMENT,
                                              StrandMode="collapsed",
                                              Elements=NULL,
                                              Log2Profile=FALSE,
                                              Window=3000 )

ChIP_BrDU_Early_Late_Enrichment_Plotter( SampleDir=BRDU_SAMPLE_DIR,
                                         Assay="BrDU",
                                         Alignment=BRDU_ALIGNMENT,
                                         StrandMode="collapsed",
                                         Log2Profile=FALSE,
                                         Window=3000 )

ChIP_BrDU_Genomic_Element_Boxplotter( SampleDir=BRDU_SAMPLE_DIR,
                                      Assay="BrDU",
                                      Alignment=BRDU_ALIGNMENT,
                                      Elements=c("EarlyOrigin", "LateOrigin"),
                                      Metric="all",
                                      Window=500,
                                      Log2Values=TRUE,
                                      ComparisonMetric="ratio.ipin.noise" )

ChIP_BrDU_Genomic_Element_Heatmap_Plotter( SampleDir=BRDU_SAMPLE_DIR,
                                           Assay="BrDU",
                                           Alignment=BRDU_ALIGNMENT,
                                           Elements=c("EarlyOrigin", "LateOrigin"),
                                           Metric="all",
                                           Window=3000,
                                           Log2Values=TRUE,
                                           OrderBy="ratio.ipin.noise" )


###############################################################################
## BLOCK 5 — PAIRED ChIP–BrDU COMPARISONS
## Uses the sample directories above; NULL y values use automatic axes.
## With *Peaks elements, PeakSource selects the common peak coordinates.
###############################################################################
COMPARISON_ALIGNMENT <- "generic"

ChIP_BrDU_Enrichment_Comparison_Plotter( ChIPSampleDir=CHIP_SAMPLE_DIR,
                                         BrDUSampleDir=BRDU_SAMPLE_DIR,
                                         Alignment=COMPARISON_ALIGNMENT,
                                         PeakSource="ChIP",
                                         Elements=c("EarlyOrigin", "LateOrigin"),
                                         Metric="all",
                                         Window=3000,
                                         Log2Profile=FALSE,
                                         y_val_chip=NULL,
                                         y_val_brdu=NULL )

ChIP_BrDU_Region_Comparison_Plotter( ChIPSampleDir=CHIP_SAMPLE_DIR,
                                     BrDUSampleDir=BRDU_SAMPLE_DIR,
                                     Chromosome="chrIV",
                                     RegionStart=400000,
                                     RegionEnd=500000,
                                     Alignment=COMPARISON_ALIGNMENT,
                                     Metric="ratio.ipin.noise",
                                     Log2Profile=FALSE,
                                     y_val_chip=NULL,
                                     y_val_brdu=NULL )
