# justthefacs
A GUI for visualizing flow cytometry data and counting cells in subpopulations defined by thresholds and polygonal regions in side vs. forward scatter plots

justthefacs() is a MATLAB GUI for performing common operations on flow cytometry data files. It is a lightweight and free alternative to more versatile commercial products like FlowJo.

Directions for installation:

1) Obtain fca_readfcs.m from the MATLAB File Exchange. The current URL is http://www.mathworks.com/matlabcentral/fileexchange/9608-fcs-data-reader/content/fca_readfcs.m. 
2) Download FCSFile.m and justthefacs.m from this repository.
3) Ensure that all three files are in directories on the MATLAB path.
4) The side scatter and forward scatter filters are currently assumed to be named 'FSC-A' and 'SSC-A'. If this name is different in your .fsc files, simply change the strings on lines 40 and 43 of FSCFile.m.

Directories for operation:

1) Load the GUI by calling justthefacs().
2) Click the Add button and select .fcs files of interest.
3) Select a file. A scatter plot should appear on the side scatter vs. forward scatter axes.
4) To consider only cells within a connected region of side vs. forward scatter plot, press the Update Bounds button, then click on the vertices of the polygon. Click on the first vertex to finish.
5) To view the histogram of values for a given filter, select it from the drop-down menu.
6) To consider only cells with fluorescence above a given value for a given filter, first select it from the drop-down menu, then type in the value to use as a threshold and press Update Threshold.
7) To copy the same side vs. forward scatter bounds and thresholds to all .fcs files in the list, press the Same bounds and settings button.
8) To show histograms for fluorescence of all files in the same channel on one plot, first select the filter of interest, then click Histogram All.
9) To export a variable describing the number of cells in each file within the side vs. forward scatter bounds, press Threshold All. The second column will show the number of cells above any additional thresholds that have been set.
