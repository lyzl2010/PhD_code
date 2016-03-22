function [ Y_hat, net, best_CV_MSE ] = myANN( X_trn, Y_trn, X_tst, Y_tst, hiddenLayerSize, trainFcn, transferFcn, K)
%% ANN
% Solve an Input-Output Fitting problem with a Neural Network
% Script generated by NFTOOL
% Created Sun Oct 27 16:28:18 SGT 2013
%
% trainFcn:
% trainbfg: BFGS quasi-Newton backpropagation
% trainbfgc: BFGS quasi-Newton backpropagation for use with NN model reference adaptive controller
% trainbr: Bayesian regularization
% trainbu: Batch unsupervised weight/bias training
% trainc: Cyclical order incremental update
% traincgb: Powell-Beale conjugate gradient backpropagation
% traincgf: Fletcher-Powell conjugate gradient backpropagation
% traincgp: Polak-Ribi�re conjugate gradient backpropagation
% traingd: Gradient descent backpropagation
% traingda: Gradient descent with adaptive learning rule backpropagation
% traingdm: Gradient descent with momentum backpropagation
% traingdx: Gradient descent with momentum and adaptive learning rule backpropagation
% trainlm: Levenberg-Marquardt backpropagation
% trainoss: One step secant backpropagation
% trainr: Random order incremental training with learning functions
% trainrp: Resilient backpropagation (Rprop)
% trainru: Random order unsupervised weight/bias training
% trains: Sequential order incremental training with learning functions
% trainscg: Scaled conjugate gradient backpropagation
%
% transferFcn:
% compet: Competitive transfer function.
% hardlim: Positive hard limit transfer function.
% hardlims: Symmetric hard limit transfer function.
% logsig: Logarithmic sigmoid transfer function.
% netinv: Inverse transfer function.
% poslin: Positive linear transfer function.
% purelin: Linear transfer function.
% radbas: Radial basis transfer function.
% radbasn: Radial basis normalized transfer function.
% satlin: Positive saturating linear transfer function.
% satlins: Symmetric saturating linear transfer function.
% softmax: Soft max transfer function.
% tansig: Symmetric sigmoid transfer function.
% tribas: Triangular basis transfer function.

% check if trainFcn exist
% by default is trainlm
if ~exist('trainFcn','var')
    trainFcn='trainlm';
end

% check if transferFcn exist
% by default is tansig
if ~exist('transferFcn','var')
    transferFcn='tansig';
end

if ~exist('K','var')
    K=5;
end

CV_MSE=zeros(1,K);
kth_ANN_MSE=zeros(1,K);
kth_ANN_pred=zeros(length(Y_tst),K);
inputs=[X_trn;X_tst]';
targets=[Y_trn;Y_tst]';
trn_Idx=(1:size(X_trn,1));
tst_Idx=trn_Idx(end)+(1:size(X_tst,1));

% cross validation
cv=cvpartition(trn_Idx, 'kfold', K);
for k=1:cv.NumTestSets
    % Create a Fitting Network
    net = fitnet(hiddenLayerSize);
    
    % Choose Input and Output Pre/Post-Processing Functions
    % For a list of all processing functions type: help nnprocess
    net.inputs{1}.processFcns = {'removeconstantrows','mapminmax'};
    net.outputs{2}.processFcns = {'removeconstantrows','mapminmax'};
    
    net.divideFcn = 'divideind';
    net.layers{1}.transferFcn=transferFcn;
    net.trainFcn = trainFcn;
    net.performFcn = 'mse';
    net.trainParam.showWindow=0;
    
    trnIdx=trn_Idx(cv.training(k));
    valIdx=trn_Idx(cv.test(k));
    net.divideParam.trainInd = trnIdx;
    net.divideParam.valInd = valIdx;
    net.divideParam.testInd = tst_Idx;
    
    % Test the Network
    [net,tr] = train(net,inputs,targets);
    outputs = net(inputs);
    errors = gsubtract(targets,outputs);
    performance = perform(net,targets,outputs);
    % Recalculate Training, Validation and Test Performance
    trainTargets = targets .* tr.trainMask{1};
    valTargets = targets  .* tr.valMask{1};
    testTargets = targets  .* tr.testMask{1};
    trainPerformance = perform(net,trainTargets,outputs);
    valPerformance = perform(net,valTargets,outputs);
    testPerformance = perform(net,testTargets,outputs);
    CV_MSE(k)=valPerformance;
    kth_ANN_MSE(k)=testPerformance;
    kth_ANN_pred(:,k)=outputs(tst_Idx)';
end
min_idx= CV_MSE==min(CV_MSE);
best_CV_MSE=min(CV_MSE);
Y_hat=kth_ANN_pred(:,min_idx);
figure();
plot(Y_hat, '.-r');hold on; plot(Y_tst);hold off;
end
