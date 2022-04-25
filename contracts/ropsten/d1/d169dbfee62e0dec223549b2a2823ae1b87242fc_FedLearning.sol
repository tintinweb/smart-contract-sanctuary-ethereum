/**
 *Submitted for verification at Etherscan.io on 2022-04-24
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

contract FedLearning {

    

    int[][] private models;

    uint public numLocalModelsRequired;
    uint public currentRound;

    int[] public globalModel;

    event globalModelUpdated();

    constructor(uint numLocalModelsRequired_) {
        numLocalModelsRequired = numLocalModelsRequired_;
    }

    function sendModel(int[] memory localModel) public {
        models.push(localModel);
        _averageModels();
    }

    function _add2Models(int[] memory modelA, int[] memory modelB) private pure returns (int[] memory sumModel) {
        require (modelA.length == modelB.length, "Size mismatch");
        uint len = modelA.length;
        
        sumModel = new int[](len);

        for (uint i = 0; i < len; i++) {
            sumModel[i] = (modelA[i] + modelB[i]);
        }

        return sumModel;
    }

    function _averageModels() private {
        require (models.length >= numLocalModelsRequired, "Not enough local models for global update");

        uint len = models[0].length;
        int[] memory aggregatedModel = new int[](len);

        for (uint i = 0; i < models.length; i++) {
            aggregatedModel = _add2Models(aggregatedModel, models[i]);
        }

        int[] memory averagedModel = new int[](len);

        for (uint i = 0; i < aggregatedModel.length; i++) {
            averagedModel[i] = aggregatedModel[i] / int256(models.length);
        }

        globalModel = averagedModel;

        emit globalModelUpdated();

        delete models;

        currentRound += 1;
    }
}