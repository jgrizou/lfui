function reshaped = reshape_to_grid(vector)
%RESHAPE_TO_GRID

if ~isvector(vector)
    error('reshape_to_grid:Input', 'vector must be 1-D')
end
gSize = sqrt(length(vector));
if mod(gSize, 1) ~= 0
    error('reshape_to_grid:InputDim', 'vector size can not be plotted on a grid')
end
reshaped = zeros(gSize, gSize);
for i = 1:length(vector)     
    line = gSize - ceil(i / gSize) + 1; 
    column =  mod(i - 1, gSize) + 1;           
    reshaped(line, column) = vector(i);
end  