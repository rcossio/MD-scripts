# MD-scripts

This are scripts I use to do protein/enzyme molecular dynamics simulations in AMBER software.
I saved them to keep them but they are quite simple and aren't documented.

FittingRESPCharges uses Gaussian 09 rev B.01 to calculate RESP charges. Usefull for depeloping forcields for ligand and special molecules. Particularly usefull because it handles the bug in G09revB.01

OrganicLigandForceField completes the creaton of a forcefield using GAFF and RESP charges.

MakeRTP generates an RTP file to use in Gromacs

MolRenamer takes a the atom names from one PDB and replaces the atom names in another PDB file. It is usefull when adapting PDB with custom atom names to a forcefield.

PlainMD contains:
 - BackboneCorrelations.sh:  it takes a trajectory and prmtop and returns correlations coeficients of the chosen mask (Default: alpha-carbons)
 - ContactAnalysis.sh: Studies the contact frequency observed in an MD and plots a result (it uses write_svg.py script)
 - GetRepresentative.sh: Returns the structure that is the most similar to the average of a trajectory. 
 - HbondAnalysis.sh: Returns Hbond frequency
 - MinHeatEq.sh: Initialized a generic MD, previous to the production phase
 - PCA.sh: Performs PCA. Also, using PCA-animate.py, produces structures that can be animated to show the componends. Note: it will animate atoms included in PCA, so perhaps use @CA,C,O,N mask
 - PlainMD.sh: Simple production run
 - RMSD_ROG.sh: Returns RMSD and/or ROG
 - Watch.sh: Generates visual output to be seen in VMD

not-finished contains unfinished or useless scripts

 This scripts are not mantained frequently and may not be user friendly. Make sure to understand what is the script doing.
 To request more information or report a bug, please write to rodrigoperez93@gmail.com
 



