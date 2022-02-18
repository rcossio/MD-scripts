#!/bin/bash

# In this example we will change the name of the atoms and residue in QueryFAD.pdb
# to the ones in TemplateFAD.pdb. The resutlt, FixedFAD.pdb, will keep the coordinates
# and numbering in QueryFAD.pdb.
#
# Note that QueryFAD.pdb can misses the H atoms. It is only necessary that QueryFAD.pdb atoms
# are contained in the TemplateFAD.pdb file

# To understand the file input/output run 

    ../PDBwPDB.py -h

# To execute this example, run 

    ../PDBwPDB.py -q QueryFAD.pdb -t TemplateFAD.pdb -f FixedFAD.pdb > log.txt


 
