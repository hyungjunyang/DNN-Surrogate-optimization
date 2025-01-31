function [trainedNet, traininfo, temp_mean, temp_std] = trainCNN(total_TOF, total_P, pos, type, pos_fit)
global N nx ny N_ens Np ...
       maxtof maxp ...
       retrain iter ...
       direc_fig

Nsample = size(pos_fit,1);
selected = 1:1:Nsample;

% total_TOF{1} = (total_TOF{1} - mean(total_TOF{1})) ./ std(total_TOF{1},0,1);
% total_TOF{2} = (total_TOF{2} - mean(total_TOF{2})) ./ std(total_TOF{2},0,1);
total_TOF{1} = (total_TOF{1}-maxtof/2)/maxtof;
total_TOF{2} = (total_TOF{2}-maxtof/2)/maxtof;
total_P{1}   = (total_P{1}-maxp)/maxp;

INPUT = [];
for j = 1:Nsample
    
    INPUT(:,:,1,j) = (reshape(total_TOF{1}(1:nx*ny,selected(j)),nx,ny)');
    INPUT(:,:,2,j) = (reshape(total_TOF{2}(1:nx*ny,selected(j)),nx,ny)');
    INPUT(:,:,3,j) = (reshape(total_P{1}(1:nx*ny,selected(j)),nx,ny)');
    INPUT(:,:,4,j) = 0*ones(ny,nx);
    
    if isempty(type)
        tp = pos(:,2*N+1:3*N);
    else
        tp = repmat(type,N_ens*Np,1);
    end
    for k = 1:N
        if tp(selected(j),k) >= 1/3
            INPUT(pos(selected(j),2*k), pos(selected(j),2*(k-1)+1), 4, j) = 1;
        elseif tp(selected(j),k) <= -1/3
            INPUT(pos(selected(j),2*k), pos(selected(j),2*(k-1)+1), 4, j) = -1;
        end
    end
    
end

temp_mean = mean(-pos_fit(selected,1));
temp_std = std(-pos_fit(selected,1), 1);
INPUT_NPV = ( - pos_fit(selected,1) - temp_mean ) / temp_std;

Nall = size(INPUT,4);
Nsamp = ceil(Nall*0.8);

aa = randperm(Nall,Nsamp);
bb = 1:1:Nall;
cc = [];
for kk = 1:Nall
    if find(kk==aa)
        continue
    end
    cc = [cc,bb(kk)];
end


miniBatchSize  = 150;
validationFrequency = floor((Nall-Nsamp)/miniBatchSize);
options = trainingOptions('adam', ...
    'MiniBatchSize',miniBatchSize, ...
    'MaxEpochs',60, ...
    'InitialLearnRate',3e-3, ...
    'LearnRateSchedule','piecewise', ...
    'LearnRateDropFactor',0.1, ...
    'LearnRateDropPeriod',20, ...
    'Shuffle','every-epoch', ...
    'ValidationData',{INPUT(:,:,:,cc),INPUT_NPV(cc,:)}, ...
    'ValidationFrequency',validationFrequency, ...
    'Plots','training-progress', ...
    'Verbose',false);
%     'Shuffle','every-epoch', ...

layers = [
    imageInputLayer([ny nx size(INPUT,3)])
    
    convolution2dLayer(3,32,'Padding','same','WeightsInitializer','glorot')
    batchNormalizationLayer
    reluLayer
    
    averagePooling2dLayer(2,'Stride',2)
    
    convolution2dLayer(3,64,'Padding','same','WeightsInitializer','glorot')
    batchNormalizationLayer
    reluLayer
    
    averagePooling2dLayer(2,'Stride',2)
    
%     convolution2dLayer(3,64,'Padding','same','WeightsInitializer','glorot')
%     batchNormalizationLayer
%     reluLayer
%     
%     averagePooling2dLayer(2,'Stride',2)
    
    convolution2dLayer(3,64,'Padding','same','WeightsInitializer','glorot')
    batchNormalizationLayer
    reluLayer
    
    averagePooling2dLayer(2,'Stride',2)
    
    convolution2dLayer(3,128,'Padding','same','WeightsInitializer','glorot')
    batchNormalizationLayer
    reluLayer
    
    averagePooling2dLayer(2,'Stride',2)
    
%     dropoutLayer(0.4)
    
    fullyConnectedLayer(128)
    batchNormalizationLayer
    reluLayer
    dropoutLayer(0.4)
    
    fullyConnectedLayer(1)
    batchNormalizationLayer
    
    regressionLayer];


[trainedNet, traininfo] = trainNetwork(INPUT(:,:,:,aa), INPUT_NPV(aa,1),layers,options);
% 
OUTPUT = predict(trainedNet,INPUT(:,:,:,cc));
OUTPUT = [OUTPUT, INPUT_NPV(cc)] .* temp_std + temp_mean;
figure; h1 = plotregression2(OUTPUT(:,2), OUTPUT(:,1));
print('-r600', '-dpng', [direc_fig '/validation data #' num2str(retrain) '_' num2str(iter) '.png']); close;
[~, I1] = sort(OUTPUT(:,1), 'ascend');
[~, I2] = sort(OUTPUT(:,2), 'ascend');
sorted_out = [I1, I2];
% as = ismember(sorted_out(1:(Nall - Nsamp)*0.1,1), sorted_out(1:(Nall - Nsamp)*0.1,2));
% asd1=length(find(as == 1))/((Nall - Nsamp)*0.1)
% as = ismember(sorted_out(1:30,2), sorted_out(1:30,1));
% asd2=length(find(as == 1))/30

% 
OUTPUT2 = predict(trainedNet,INPUT(:,:,:,aa));
OUTPUT2 = [OUTPUT2, INPUT_NPV(aa)].* temp_std + temp_mean;
figure; h2 = plotregression2(OUTPUT2(:,2), OUTPUT2(:,1));
print('-r600', '-dpng', [direc_fig '/training data #' num2str(retrain) '_' num2str(iter) '.png']); close;
end