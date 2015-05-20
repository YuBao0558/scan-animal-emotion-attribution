load surf1_design.mat
tmp = Seeker;
soa = diff(tmp(:,5));
adjust = soa - 0.25;
for i = 1:length(tmp)-1
    tmp(i+1,5) = tmp(i,5)+adjust(i);
end
Seeker = tmp;

save surf1_design.mat Seeker
    