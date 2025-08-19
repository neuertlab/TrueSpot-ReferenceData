# TrueSpot Benchmarking Data Repository
This repository is for scripts, figures, and smaller data tables used for benchmarking RNA-FISH spot detection tools as described in Hospelhorn, et al. 2025. Image stacks and large result files are hosted elsewhere, linked below.

## Contents
The included `Documentation.md` file describes the processes, data tables, and scripts used for various analyses in more detail. 

Generally, the `figures` subdirectory contains figure elements used in the benchmarking paper in `.svg` or `.png` format. Some remain as they were when output by R or MATLAB, but those included in final figures have had some internal annotation (grouping, layer renaming) and in some cases heavy aesthetic changes made. All figure pieces should be regeneratable from included data tables and scripts as described in `Documentation.md`, if desired.

The `tables` subdirectory contains the smaller data tables used for benchmarking - both input and output. These include information about the image stacks used, results dump tables, and calculated stats tables among others.

The `scripts` subdirectory contains code used for running tools for benchmarking, but also for various analyses and data organization. Scripts are predominately a mix of Python, R, and MATLAB. MATLAB scripts have been grouped together instead of split by use simply to make them easier to run if need be since some call each other. `MATLAB Scripts.txt` is a small tab-delimited table that lists some of the important benchmarking processes and the MATLAB scripts that handle them.

## External Data Links
Large data files and file collections used for benchmarking are not hosted in this repo due to their size. Instead, we provide links for them here.

### Image Stacks
* [Yeast time course](https://doi.org/10.17867/10000118) [(Li & Neuert 2019)](https://www.nature.com/articles/s41597-019-0106-6)
* [Yeast Msb2-GFP & Opy2-GFP](https://www.ebi.ac.uk/biostudies/studies/S-BIAD1316) (Hospelhorn, et al. 2025)
* [mESC Xist, Tsix, & Histone](https://www.ebi.ac.uk/biostudies/studies/S-BIAD1316) ([Kesler, et al. 2025](https://pubmed.ncbi.nlm.nih.gov/40328749/))
* Munsky lab HeLa images [(Vo, et al. 2023)](https://www.frontiersin.org/articles/10.3389/fcell.2023.1133994/full) - Available from Munsky lab upon request.
* [Neuert lab simulated images](https://www.ebi.ac.uk/biostudies/studies/S-BIAD1316) (Hospelhorn, et al. 2025)
* RS-FISH benchmarking set [(Bahry, et al. 2022)](https://www.nature.com/articles/s41592-022-01669-y)

### Results Data

All other large data including:
* Results files for each image including call sets, reference sets, and performance calculations.
* Cell segmentation masks
* Simulated image ground truth keys
* deepBlink retrained model data

Can be found in our [BioStudies archive](https://www.ebi.ac.uk/biostudies/studies/S-BIAD1316)
