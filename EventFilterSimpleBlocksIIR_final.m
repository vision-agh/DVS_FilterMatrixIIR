classdef EventFilterSimpleBlocksIIR_final < handle
    %CALCULATEFEATURES Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        FrameSize
        FilterLength
        Scale
        UpdateFactor
        TimeMap
        ActiveMap
        EventsTrue
        EventsFalse
        ValidEvents
        InvalidEvents
        CurrentTs
        ImageData
    end
    
    methods
        function obj = EventFilterSimpleBlocksIIR(frame_size, filter_length, scale, update_factor)
            obj.FrameSize = frame_size;
            obj.FilterLength = filter_length;
            obj.Scale = scale;
            obj.UpdateFactor = update_factor;
            obj.TimeMap = zeros(floor(frame_size(1)/scale), floor(frame_size(2)/scale));
            obj.ActiveMap = zeros(floor(frame_size(1)/scale), floor(frame_size(2)/scale));
            obj.ValidEvents = 0;
            obj.InvalidEvents = 0;
            obj.CurrentTs = 0;
        end

        function events = getEventsTrue(obj)
            events = obj.EventsTrue;
        end

        function events = getEventsFalse(obj)
            events = obj.EventsFalse;
        end
        
        function processEvents(obj, events)
            eventsBin = false(1, size(events, 1));
            for iter = 1:size(events, 1)
                event = events(iter, :);
                eventsBin(iter) = obj.filterEvent(event);
                obj.updateFeatures(event);
                obj.CurrentTs = event(4);
            end
            obj.updateEmpty()
            obj.EventsTrue = events(eventsBin, :);
            obj.EventsFalse = events(~eventsBin, :);
            obj.ValidEvents = obj.ValidEvents + size(obj.EventsTrue, 1);
            obj.InvalidEvents = obj.InvalidEvents + size(obj.EventsFalse, 1);
        end

        function correct = filterEvent(obj, event)
            cellY = floor(event(2)/obj.Scale)+1;
            cellX = floor(event(1)/obj.Scale)+1;
            thr_ts = obj.TimeMap(cellY, cellX);
            diff_ts = event(4) - thr_ts;
            correct = diff_ts < obj.FilterLength;
        end

        function updateFeatures(obj, event)
            obj.updateFilteredTimestamp(event);
            obj.updateActive(event);
        end

        function updateFilteredTimestamp(obj, event)
            cellY = floor(event(2)/obj.Scale)+1;
            cellX = floor(event(1)/obj.Scale)+1;
            cell_filtered_time = obj.TimeMap(cellY, cellX);
            new_filtered_time = cell_filtered_time * (1 - obj.UpdateFactor) + event(4) * obj.UpdateFactor;
            obj.TimeMap(cellY, cellX) = new_filtered_time;
        end

        function updateActive(obj, event)
            cellY = floor(event(2)/obj.Scale)+1;
            cellX = floor(event(1)/obj.Scale)+1;
            obj.ActiveMap(cellY, cellX) = 1;
        end

        function updateEmpty(obj)
            scaled_size = size(obj.TimeMap);
            for y = 1:scaled_size(1)
                for x = 1:scaled_size(2)
                    if ~obj.ActiveMap(y, x)
                        new_filtered_time = obj.TimeMap(y, x) * (1 - obj.UpdateFactor) + obj.CurrentTs * obj.UpdateFactor;
                        obj.TimeMap(y, x) = new_filtered_time;
                    end
                end
            end
            obj.ActiveMap(:, :) = 0;
        end

        function displayFilter(obj)
            image = uint8(ones(obj.FrameSize(1), obj.FrameSize(2), 3)) * 255;
            if ~isempty(obj.EventsFalse)
                for ind = 1:size(obj.EventsFalse, 1)
                    image(obj.EventsFalse(ind, 2)+1, obj.EventsFalse(ind, 1)+1, :) = [255, 0, 0];
                end
            end
            if ~isempty(obj.EventsTrue)
                for ind = 1:size(obj.EventsTrue, 1)
                    image(obj.EventsTrue(ind, 2)+1, obj.EventsTrue(ind, 1)+1, :) = [0, 255, 0];
                end
            end
            figure(5);
            imshow(image);
            obj.ImageData = image;
        end

        function mainDisplay(obj)
            obj.displayFilter();
        end
        
    end
end

