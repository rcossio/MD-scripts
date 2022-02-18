# MakeRTP

This is a small script to create RPT files.
It was intended to help with the creation of new residues 
when simulating with SIRAH forcefield.


# Notes

THE SCRIPT IS UNDER DEVELOPEMENT and has not been deeply tested.
Some issues to fix later:

	- PDB is read by columns and it showld be read by character position. PDBs with an aditional
          column (like the chain) will fail with the script
        - RTP file is not printed in an ordered manner
        - It would be nice to add a small tutorial on how to create a residue for SIRAHff
