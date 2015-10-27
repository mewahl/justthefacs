classdef FCSFile < handle
    % This class is designed for storing key data about an FCS file (such
    % as the filename, FSC/SSC bounding information, and filter names/
    % threshold values. The events themselves are not stored in the FCSFile
    % object, but can be accessed by functions in this class file that load
    % and interpret the .fcs file.

    properties
        FileName = '';
        BoundsX = [];
        BoundsY = [];
        FilterNames = {};
        FilterThresholds = [];
        % Just some default values so the box in plainly visible when
        % the FSC/SSC data are first plotted
        FSCFilter = 0;
        SSCFilter = 0;
    end

    methods
        function FF = FCSFile(FileName)
            % This constructor function identifies which filters correspond
            % to forward scatter (FSC) and side scatter (SSC). If you
            % prefer to use width ("flight-time") FSC and SSC values for
            % gating, change FSC-A to FSC-W, etc. (You may also need to
            % change the axes limits in the "showfscssc" function below.)
            
            % Get the header information; ignore the data for now
            FF.FileName = FileName;
            [fcsdat, fcshdr] = fca_readfcs(FF.FileName);
            clear fcsdat;
            
            % From the header information, get the filter names and set the
            % thresholds for these filters to zero by default.
            for i=1:fcshdr.NumOfPar
                FF.FilterNames{i} = fcshdr.par(1,i).name;
                FF.FilterThresholds(i) = 0;
            end
            
            % Find the filters corresponding to forward and side scatter.
            for i=1:length(FF.FilterNames)
                if strcmp(FF.FilterNames{i},'FSC-A')
            	    FF.FSCFilter = i;
                else
                    if strcmp(FF.FilterNames{i},'SSC-A')
                        FF.SSCFilter = i;
                    end
                end
            end
            if FF.FSCFilter == 0 | FF.SSCFilter == 0
                err('Could not find both FSC and SSC filters')
            end
            
            % Set default forward and side scatter bounds.
            FF.BoundsX = [0.5E5 0.5E5 1E5 1E5];
            FF.BoundsY = [1E4 5E4 5E4 1E4];
        end
      
      function FilterValues = getfiltervalues(FF,i)
          % Retrieves the fluorescence values for a given filter id for all
          % events within the FSC/SSC bounding region. Useful for plotting
          % a histogram, thresholding, or calculating mean/standard
          % deviation.
          [fcsdat, fcshdr] = fca_readfcs(FF.FileName);
          InsideBounds = inpolygon(fcsdat(:,FF.FSCFilter), ...
            fcsdat(:,FF.SSCFilter),FF.BoundsX,FF.BoundsY);
          FilterValues = fcsdat(InsideBounds,i);
      end
        
      function setbounds(FF,NewBoundsX,NewBoundsY)
          % Necessary because the object properties cannot be changed
          % directly by functions defined outside of the class file.
          FF.BoundsX = NewBoundsX;
          FF.BoundsY = NewBoundsY;
      end
      
      function [Total, Above] = threshold(FF,FilterNumber)
          % This function performs FSC/SSC bounding on all particles in a
          % .fcs file, then determines how many of those particles also
          % have a value for the filter of interest above a threshold
          % value. (Useful for counting how many cells are CFP+, for
          % example.)
          
          % Read in the data from the FCS file of interest using a
          % third-party script. Won't actually use the header.
          [fcsdat, fcshdr] = fca_readfcs(FF.FileName);
          
          % Find cells within the FSC/SSC boundaries
          InsideBounds = FF.getfiltervalues(FilterNumber);
          Total = length(find(InsideBounds > 0));
          Above = length(find(InsideBounds > FF.FilterThresholds( ...
              FilterNumber)));
      end
      
      function [Mean, Stdev] = meanandstdev(FF,FilterNumber)
          % This function performs FSC/SSC bounding on all particles in a
          % .fcs file, then determines the mean and standard deviation of
          % values for a particular filter of interest.
          InsideBounds = FF.getfiltervalues(FilterNumber);
          Mean = mean(InsideBounds);
          Stdev = std(InsideBounds);
      end
      
      function showfscssc(FF,hAxes)
          % This function plots the FSC/SSC data for the first 10000 events
          % per .fcs file as well as the current FSC/SSC bounds.
          
          % Make sure the current axes are for the FSC and SSC plot
          axes(hAxes);
                    
          % Load the file and draw the first 10000 (or fewer) points
          [fcsdat, fcshdr] = fca_readfcs(FF.FileName);
          fcsdat = fcsdat(1:min(10000,length(fcsdat)),:);
          scatter(fcsdat(:,FF.FSCFilter), fcsdat(:,FF.SSCFilter),1, 'k');
          hold on;
          
          % Draw the polygonal FSC/SSC bounding region
          hroi=fill(FF.BoundsX,FF.BoundsY,'r');
          set(hroi,'FaceColor','none','EdgeColor',[1 0 0]);
          
          % Improve the plot's appearance
          xlim([0 250000]);
          ylim([0 250000]);
          xlabel('FSC-A');
          ylabel('SSC-A');
      end
    end
end
