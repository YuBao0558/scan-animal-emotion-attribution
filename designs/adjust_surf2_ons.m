load surf2_designs.mat
for i = 1:length(allSeeker)
    
    tmp = allSeeker{i};
    soa = diff(tmp(:,6));
    adjust = soa - 0.5;
    for t = 1:length(tmp)-1
        tmp(t+1,6) = tmp(t,6)+adjust(t);
    end
    
    allSeeker{i} = tmp;
    
end
save surf2_designs.mat qstim allSeeker
    