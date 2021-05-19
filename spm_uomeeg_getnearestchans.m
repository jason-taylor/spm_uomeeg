function [idx,d] = spm_uomeeg_getnearestchans(X,Y,k)

% Gets K nearest channel indices (and distances).
% Euclidean distances only (for the moment).
% From rayreng's response here:
% https://stackoverflow.com/questions/27475978/finding-k-nearest-neighbors-and-its-implementation

Q = size(Y, 1);
M = size(X, 2);

nA = sum(Y.^2, 2); %// Sum of squares for each row of A
nB = sum(X.^2, 2); %// Sum of squares for each row of B
D = bsxfun(@plus, nA, nB.') - 2*Y*X.'; %// Compute distance matrix
D = sqrt(D); %// Compute square root to complete calculation 

%// Sort the distances 
[d, ind] = sort(D, 2);

%// Get the indices of the closest distances
ind_closest = ind(:, 1:k);

%// Also get the nearest points
x_closest = permute(reshape(X(ind_closest(:), :).', M, k, []), [2 1 3]);

row_indices = repmat((1:Q).', 1, k);
linear_ind = sub2ind(size(d), row_indices, ind_closest);
dist_sorted = D(linear_ind);

%// Return values:
idx = ind_closest;
d = dist_sorted;

return