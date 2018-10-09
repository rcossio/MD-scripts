# -*- coding: utf-8 -*-

# python write_svg.py matrix.all.dat > nada.svg
import sys
import numpy as np

head= '''<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<!-- Created with Inkscape (http://www.inkscape.org/) -->

<svg
   xmlns:dc="http://purl.org/dc/elements/1.1/"
   xmlns:cc="http://creativecommons.org/ns#"
   xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
   xmlns:svg="http://www.w3.org/2000/svg"
   xmlns="http://www.w3.org/2000/svg"
   xmlns:sodipodi="http://sodipodi.sourceforge.net/DTD/sodipodi-0.dtd"
   xmlns:inkscape="http://www.inkscape.org/namespaces/inkscape"
   width="210mm"
   height="297mm"
   viewBox="0 0 210 297"
   version="1.1"
   id="svg4637"
   inkscape:version="0.92.1 unknown"
   sodipodi:docname="try_script.svg">
  <defs
     id="defs4631" />
  <sodipodi:namedview
     id="base"
     pagecolor="#ffffff"
     bordercolor="#666666"
     borderopacity="1.0"
     inkscape:pageopacity="0.0"
     inkscape:pageshadow="2"
     inkscape:zoom="0.98994949"
     inkscape:cx="100.2744"
     inkscape:cy="197.9899"
     inkscape:document-units="mm"
     inkscape:current-layer="layer1"
     showgrid="false"
     inkscape:window-width="1301"
     inkscape:window-height="744"
     inkscape:window-x="65"
     inkscape:window-y="24"
     inkscape:window-maximized="1" />
  <metadata
     id="metadata4634">
    <rdf:RDF>
      <cc:Work
         rdf:about="">
        <dc:format>image/svg+xml</dc:format>
        <dc:type
           rdf:resource="http://purl.org/dc/dcmitype/StillImage" />
        <dc:title></dc:title>
      </cc:Work>
    </rdf:RDF>
  </metadata>
  <g
     inkscape:label="Layer 1"
     inkscape:groupmode="layer"
     id="layer1">
'''

tail = '''
  
  </g>
</svg>
'''

def rectangle_string(x,y,rectID,opacity):
        string= '''
    <rect
       style="opacity:1;fill:#ff0000;fill-opacity:1.0;stroke:#ffffff;stroke-width:0.30000001;stroke-linejoin:miter;stroke-miterlimit:3.79999995;stroke-dasharray:none;stroke-dashoffset:0;stroke-opacity:1;paint-order:fill markers stroke"
       id="rectA-'''+str(rectID)+'''"
       width="9.8326273"
       height="9.8326273"
       x="'''+str(x)+'''"
       y="'''+str(y)+'''" />
    <rect
       style="opacity:1;fill:#00ff00;fill-opacity:'''+str(opacity)+''';stroke:#ffffff;stroke-width:0.30000001;stroke-linejoin:miter;stroke-miterlimit:3.79999995;stroke-dasharray:none;stroke-dashoffset:0;stroke-opacity:1;paint-order:fill markers stroke"
       id="rectB-'''+str(rectID)+'''"
       width="9.8326273"
       height="9.8326273"
       x="'''+str(x)+'''"
       y="'''+str(y)+'''" />
'''
        return string


# aca empieza el script -------------------------------------------------------------------------

matrix = []
for line in open(sys.argv[1]):
	matrix.append(map(float,line.split()))
matrix = np.array(matrix,dtype=float)
matrix = matrix[:,::-1]

sys.stdout.write(head)
x0=6.4229708
y0=279.98843
dx = 9.8326273 + 0.15
dy = 9.8326273 + 0.15

for i in range (matrix.shape[0]):
	for j in range(matrix.shape[1]):
		x = x0 + i*dx
	        y = y0 - j*dx
	
		opacity = matrix[i,j] 
		rect=rectangle_string(x,y,i,min([1.0,opacity]))
		sys.stdout.write(rect)

sys.stdout.write(tail)

