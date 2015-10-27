function justthefacs
   % A GUI for loading flow cytometry files, applying polygonal forward
   % scatter and side scatter cutoffs, counting events above and below
   % fluorescence thresholds, and producing fluorescence histograms.

   % Global variables
   ArrayOfFCSFiles = {}; % Will hold objects of class FCSFile.
   hColors = [ 0 0 0; 1 0 0; 1 0.5 0; 0 0.7 0; 0 1 1; 0 0 1; 1 0 1; ...
       0.7 0.7 0.7;]; % Colors to cycle through in multi-file histograms
   HistogramBins = logspace(0,5,200); % The usual range of arbitrary units.
   XTicks = [1 10 100 1000 10000 100000];
   XLimits = [1 100000];
 
   %  Begin building the GUI.
   f = figure('Visible', 'off', 'MenuBar', 'none', 'Resize', 'off', ...
       'Name', 'Just the FACS, man!', 'Position', [0,0,700,300], ...
       'Color',[1 1 1]);
   
   % GUI elements for the list of current files
   hFileLabel = uicontrol('Style', 'text', 'String', ...
       'Files of Interest', 'Position', [0 285 140 15]);
   hFileList = uicontrol(f, 'Style', 'listbox', 'String', {}, ...
       'Value', 1, 'Callback', {@ChangeFileSelection_Callback}, ...
       'Position', [0 215 140 70]);
   hAdd = uicontrol('Style', 'pushbutton', 'String', 'Add', ...
       'Position', [0,195,70,20], 'Callback', {@AddButton_Callback});
   hRemove = uicontrol('Style', 'pushbutton', 'String', 'Remove', ...
       'Position', [70,195,70,20], 'Callback', {@RemoveButton_Callback});
   
   % GUI elements for functions that use all of the current files at once.
   hAllFilesSettings = uicontrol('Style', 'pushbutton', 'String', ...
       'Same bounds/settings', 'Position', [0,175,140,20], 'Callback', ...
       {@AllFilesSettingsButton_Callback});
   hAllFilesHist = uicontrol('Style', 'pushbutton', 'String', ...
       'Histogram All', 'Position', [0,155,140,20], 'Callback', ...
       {@AllFilesHistButton_Callback});
   hAllFilesThreshold = uicontrol('Style', 'pushbutton', 'String', ...
       'Threshold All', 'Position', [0,135,140,20], 'Callback', ...
       {@AllFilesThresholdButton_Callback});
   hAllFilesMean = uicontrol('Style', 'pushbutton', 'String', ...
       'Mean/Stdev All', 'Position', [0,115,140,20], 'Callback', ...
       {@AllFilesMeanButton_Callback});
   
   % GUI elements for setting the FSC/SSC bounds, current filter of
   % interest, and filter threshold (for counting events above and below a
   % certain value)
   hUpdateBounds = uicontrol('Style', 'pushbutton', 'String', ...
       'Update Bounds', 'Position', [0,95,140,20], 'Callback', ...
       {@UpdateBoundsButton_Callback});
   hFilterLabel = uicontrol('Style', 'text', 'String', 'Filter:', ...
       'Position', [0 65 50 25]);
   hFilterPopup = uicontrol('Style', 'popupmenu', 'String', ...
       {'No filters yet'}, 'Position', [50 70 90 20], 'Callback', ...
       {@ChangeFilterSelection_Callback});
   hThresholdLabel = uicontrol('Style', 'text', 'String', 'Threshold:', ...
       'Position', [0 50 70 15]);
   hThresholdEntry = uicontrol('Style', 'edit', 'String', '0', ...
       'Position', [70 50 70 15]);
   hUpdateThreshold = uicontrol('Style', 'pushbutton', 'String', ...
       'Update Threshold', 'Position', [0,30,140,20], 'Callback', ...
       {@UpdateThresholdButton_Callback});
   
   % GUI elements for reporting on # of cells above and below the threshold
   hTotalLabel = uicontrol('Style', 'text', 'String', 'Cells Total:', ...
       'Position', [0 15 70 15]);
   hAboveLabel = uicontrol('Style', 'text', 'String', 'Cells Above:', ...
       'Position', [0 0 70 15]);
   hTotalEntry = uicontrol('Style', 'edit', 'String', '0','Position', ...
       [70 15 70 15]);
   hAboveEntry = uicontrol('Style', 'edit', 'String', '0','Position', ...
       [70 0 70 15]);
   
   % The FSC-SSC and filter of interest axes
   hAxes = axes('Units', 'Pixels', 'Position', [190 70 190 190]);
   xlabel(hAxes, 'FSC-A');
   ylabel(hAxes, 'SSC-A');
   hAxesFilter = axes('Units', 'Pixels', 'Position', [450 70 190 190]);
   xlabel(hAxesFilter, 'Filter of interest');
   ylabel(hAxesFilter, 'Count');
   
   % Improves the appearance of the GUI
   align([hFileList, hFileLabel], 'Center', 'None'); 
   set([f, hAboveLabel, hAllFilesThreshold, hAllFilesSettings, ...
       hUpdateBounds, hTotalLabel, hTotalEntry, hAllFilesHist, ...
       hAboveEntry, hFileLabel, hFilterLabel, hAxes, hAxesFilter, hAdd, ...
       hRemove, hFileList, hFilterPopup, hThresholdLabel, ...
       hThresholdEntry, hUpdateThreshold, hAllFilesMean], 'Units', ...
       'normalized');
   movegui(f, 'center')
   set(f, 'Visible', 'on');
   
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%                Subroutines used by callback functions                   %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

   function UpdateThresholdCounts
       % When the filter of interest threshold value is updated, or when
       % the current filter is changed in the drop-down menu, update the
       % total # of cells and the # of cells above the threshold. Calls a
       % function defined in the class file that first filters events by
       % FSC/SSC, then checks the values for the filter of interest. Any
       % negative filter values are ignored as error events.
        [Total, Above] = ArrayOfFCSFiles{get(hFileList, ...
            'Value')}.threshold(get(hFilterPopup, 'Value'));
        set(hTotalEntry, 'String', num2str(Total));
        set(hAboveEntry, 'String', num2str(Above));
   end

   function PlotHistogram()
       % When the filter of interest threshold value is updated, or when
       % the current filter is changed in the drop-down menu, replot the
       % histogram for the filter of interest. Uses a function in the class
       % file to sort by FSC/SSC and return only appropriate event values.
       % Plots the threshold value for comparison.
       EventValues = ArrayOfFCSFiles{get(hFileList, ...
           'Value')}.getfiltervalues(get(hFilterPopup, 'Value'));
       axes(hAxesFilter);
       BinnedValues = histc(EventValues, HistogramBins);
       BinnedValues = BinnedValues .* 1 / max(BinnedValues);
       plot(HistogramBins, BinnedValues, 'Color', [0 0 0]);
       set(gca, 'XScale', 'log');
       xlim(XLimits);
       a = ArrayOfFCSFiles{get(hFileList, ...
           'Value')}.FilterNames{get(hFilterPopup, 'Value')};
       title(strcat(a, ' histogram'));
       xlabel(a);
       set(hAxesFilter, 'XTick', XTicks)
       ylabel('Normalized count');
       line([ArrayOfFCSFiles{get(hFileList, ...
           'Value')}.FilterThresholds(get(hFilterPopup, ...
           'Value')) ArrayOfFCSFiles{get(hFileList, ...
           'Value')}.FilterThresholds(get(hFilterPopup, ...
           'Value'))], [0 1], 'Color', [0 0 1]);
   end
   
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%                          Callbacks for buttons                          %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   
   function AllFilesSettingsButton_Callback(source,eventdata)
       % Sets the FSC/SSC bounds and current filter threshold for all
       % current files. Makes an effort to match the filter name across
       % files, in case they have different filter numbers/orders.
       CurrentFilterName = ArrayOfFCSFiles{get(hFileList, ...
           'Value')}.FilterNames{get(hFilterPopup, 'Value')};
       CurrentThreshold = ArrayOfFCSFiles{get(hFileList, ...
           'Value')}.FilterThresholds(get(hFilterPopup, 'Value'));
       CurrentBoundsX =  ArrayOfFCSFiles{get(hFileList, 'Value')}.BoundsX;
       CurrentBoundsY =  ArrayOfFCSFiles{get(hFileList,'Value')}.BoundsY;
       for i=1:length(ArrayOfFCSFiles)
            ArrayOfFCSFiles{i}.BoundsX = CurrentBoundsX;
            ArrayOfFCSFiles{i}.BoundsY = CurrentBoundsY;
            FilterNumber = find(ismember(ArrayOfFCSFiles{i}.FilterNames, ...
                CurrentFilterName));
            % What to do if the relevant filter can't be found
            if isempty(FilterNumber)
                fprintf(['The file %s does not have a %s filter; ', ...
                    'could not set filter threshold.\n'], ...
                    ArrayOfFCSFiles{i}.FileName, CurrentFilterName);
            else
                ArrayOfFCSFiles{i}.FilterThresholds(FilterNumber) = ...
                    CurrentThreshold;
            end     
       end    
   end
   
   function AllFilesHistButton_Callback(source,eventdata)
        % Plots a histogram with a line for each current file. Tries to
        % match the filter name across files (in case the number or order
        % of filters is different in each file).
        
        g = figure('Position',[200,200,450,300]);
        LegendLabels = {};
        CurrentFilterName = ArrayOfFCSFiles{get(hFileList, ...
            'Value')}.FilterNames{get(hFilterPopup, 'Value')};

        for i=1:length(ArrayOfFCSFiles)
            % Find the corresponding filter
            FilterNumber = find(ismember( ...
                ArrayOfFCSFiles{i}.FilterNames, CurrentFilterName));
            if isempty(FilterNumber)
                fprintf(['The file %s does not have a %s filter; ', ...
                    'could not plot on histogram.\n'], ...
                    ArrayOfFCSFiles{i}.FileName, CurrentFilterName);
            else
                % Plot the histogram for this file
                EventValues = ArrayOfFCSFiles{i}.getfiltervalues( ...
                    FilterNumber);
                BinnedValues = histc(EventValues, HistogramBins);
                BinnedValues = BinnedValues .* 1 / max(BinnedValues);
                plot(HistogramBins, BinnedValues, 'Color', ...
                    hColors(mod(i-1,8)+1, :)); hold on;
                LegendLabels{i} = ArrayOfFCSFiles{i}.FileName;
            end        
        end
        
        % Format the plot
        xlabel(strcat(CurrentFilterName,' (A.U.)'));
        set(gca, 'XTick', XTicks)
        ylabel('Count (scaled)');
        set(gca, 'XScale', 'log');
        xlim(XLimits);
        legend(LegendLabels);
        
        % Make the original figure active again
        figure(f)
        
   end

   function AllFilesThresholdButton_Callback(source, eventdata)
       % For each current file, calculate the total number of cells above
       % and below the threshold for the current filter of interest, gating
       % on FSC/SSC. Attempts to match the filter name across files (in
       % case the number or order of filters is different in each file).
       % Stores output in the Matlab workspace.
       
       TotalAndAbove = [];
       Labels = {};
       CurrentFilterName = ArrayOfFCSFiles{get(hFileList, ...
           'Value')}.FilterNames{get(hFilterPopup, 'Value')};
       
       for i=1:length(ArrayOfFCSFiles)
           FilterNumber = find(ismember(ArrayOfFCSFiles{i}.FilterNames, ...
               CurrentFilterName));
           if isempty(FilterNumber)
               fprintf(['The file %s does not have a %s filter; could', ...
                   ' not threshold.\n'], ArrayOfFCSFiles{i}.FileName, ...
                   CurrentFilterName);
           else
               % Threshold the file
               [Total, Above] = ArrayOfFCSFiles{i}.threshold(FilterNumber);
               TotalAndAbove(i,1:2) = [Total, Above];
               Labels{i} = ArrayOfFCSFiles{i}.FileName;
           end      
       end
       assignin('base', 'Labels', Labels);
       assignin('base', 'TotalAndAbove', TotalAndAbove);
   end

   function AllFilesMeanButton_Callback(source, eventdata)
       % Calculate the mean and standard deviation of the values for the
       % selected filter, filtering by FSC and SSC (but not by filter
       % threshold), for all current files. Attempts to match the filter
       % name across files (in case the number or order of filters is
       % different in each file). Store output in the Matlab workspace.
       
       MeanAndStdev = [];
       Labels = {};
       CurrentFilterName = ArrayOfFCSFiles{get(hFileList, ...
           'Value')}.FilterNames{get(hFilterPopup, 'Value')};
       
       for i=1:length(ArrayOfFCSFiles)
           FilterNumber = find(ismember(ArrayOfFCSFiles{i}.FilterNames, ...
               CurrentFilterName));
           if isempty(FilterNumber)
               fprintf(['The file %s does not have a %s filter; could', ...
                   ' not threshold.\n'], ArrayOfFCSFiles{i}.FileName, ...
                   CurrentFilterName);
           else
               % Calculate the mean and standard deviation
               [Mean, Stdev] = meanandstdev(ArrayOfFCSFiles{i}, ...
                   FilterNumber);
               MeanAndStdev(i,1:2) = [Mean, Stdev];
               Labels{i} = ArrayOfFCSFiles{i}.FileName;
           end      
           
       end
       assignin('base', 'Labels', Labels);
       assignin('base', 'MeanAndStdDev', MeanAndStdev);
   end
   
   function AddButton_Callback(source,eventdata)
       % Add one or more files to the list of current files. Handles the
       % number of files to add dynamically by assessing the variable
       % type returned from uigetfile.
       
       ListOfFiles = get(hFileList, 'String');
       [LocalFileNames, LocalFilePath] = uigetfile('*.fcs', ...
           'Add an FCS file', 'MultiSelect', 'on');
       
       % Filenames might be a string, cell array, or numeric
       if isa(LocalFileNames, 'cell')
           for i=1:length(LocalFileNames)
               ListOfFiles{length(ListOfFiles) + 1} = fullfile( ...
                   LocalFilePath, LocalFileNames{i});
               ArrayOfFCSFiles{length(ArrayOfFCSFiles)+1} = FCSFile( ...
                   fullfile(LocalFilePath, LocalFileNames{i}));
           end
           set(hFileList, 'String', ListOfFiles);
       elseif isa(LocalFileNames,'numeric')
           % No files were selected - user probably changed their mind
           return;
       else
           ListOfFiles{length(ListOfFiles) + 1} = fullfile( ...
               LocalFilePath, LocalFileNames);
           set(hFileList, 'String', ListOfFiles);
           ArrayOfFCSFiles{length(ArrayOfFCSFiles)+1} = FCSFile( ...
               fullfile(LocalFilePath, LocalFileNames));
       end
       
   end

   function RemoveButton_Callback(source, eventdata) 
       % Remove the selected file from the list of current files, and wipe
       % all of the old data off the screen.
       
       ListOfFiles = get(hFileList, 'String');
       SelectedFile = get(hFileList, 'Value');
       ListOfFiles(SelectedFile) = [];
       
       ArrayOfFCSFiles(SelectedFile) = [];
       set(hFileList, 'Value', 1);
       set(hFileList, 'String', ListOfFiles);
       cla(hAxes);
       cla(hAxesFilter);
       set(hFilterPopup, 'Value', 1);
       set(hFilterPopup, 'String', 'No Filters Yet');
       set(hTotalEntry, 'String', '0');
       set(hAboveEntry, 'String', '0');
       set(hThresholdEntry, 'String', '0');
   end


   function UpdateThresholdButton_Callback(source, eventdata)
       % Once a new threshold value is typed into the input box, pressing
       % this button updates the stored threshold value, replots the
       % histogram with the new threshold value, and updates the threshold
       % counts in the bottom-right of the window.
       
       ArrayOfFCSFiles{get(hFileList, 'Value')}.FilterThresholds( ...
           get(hFilterPopup,'Value')) = str2num(get(hThresholdEntry, ...
           'String'));
       PlotHistogram();
       UpdateThresholdCounts;
   end

   function UpdateBoundsButton_Callback(source, eventdata)
       % Allows the user to define a polygon on the FSC/SSC axes to use for
       % filtering the cells of interest. Once drawn, the program redraws
       % the histogram and updates the threshold counts (since these both
       % rely on FSC/SSC gating.
       
       hBounds = impoly(hAxes);
       BoundPosition = getPosition(hBounds)';
       ArrayOfFCSFiles{get(hFileList, 'Value')}.setbounds( ...
           BoundPosition(1,:), BoundPosition(2,:));
       cla(hAxes);
       ArrayOfFCSFiles{get(hFileList, 'Value')}.showfscssc(hAxes);
       PlotHistogram();
       UpdateThresholdCounts;
   end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                   Drop-down menu and list callbacks                     %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
          
   function ChangeFileSelection_Callback(source, eventdata)
       % When a new file is selected, the axes must be redrawn, the filter
       % names drop-down box updated appropriately, and the threshold
       % counts rewritten in the lower left-hand corner.
       cla(hAxes);
       ArrayOfFCSFiles{get(hFileList, 'Value')}.showfscssc(hAxes);
       set(hFilterPopup, 'String', ArrayOfFCSFiles{get(hFileList, ...
           'Value')}.FilterNames);
       set(hThresholdEntry, 'String', num2str(ArrayOfFCSFiles{get( ...
           hFileList, 'Value')}.FilterThresholds(get(hFilterPopup, ...
           'Value'))));
       cla(hAxesFilter);
       PlotHistogram();
       UpdateThresholdCounts;
   end

   function ChangeFilterSelection_Callback(source, eventdata) 
        % When a new filter is selected from the drop-down box, update the
        % threshold value to match the stored value, replot the histogram,
        % and update the threshold counts in the lower-left-hand corner.
        
        set(hThresholdEntry, 'String', num2str(ArrayOfFCSFiles{get(...
            hFileList, 'Value')}.FilterThresholds(get(hFilterPopup, ...
            'Value'))));
        PlotHistogram();
        UpdateThresholdCounts;
   end

end 
