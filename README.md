# GORG Classifier

## Outputs

The final annotated sequences are available in `./results/annotations/${sample}_annotated.txt.gz`. The columns
are defined as:

+ status - classified ("C") or unclassified ("U")
+ sequence ID
+ taxonomy ID
+ length
+ taxonomy IDs used in LCA
+ sequence IDs used in the LCA
+ protein sequence
+ taxonomic lineage
+ prokka gene
+ swissprot gene
+ prokka EC
+ swissprot EC
+ prokka product
+ swissprot product
+ eggNOG
+ KO
+ Pfam
+ CAZy
+ TIGRFAMs
