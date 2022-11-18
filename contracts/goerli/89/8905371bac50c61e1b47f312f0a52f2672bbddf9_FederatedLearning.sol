/**
 *Submitted for verification at Etherscan.io on 2022-11-18
*/

pragma solidity ^0.8.7;
contract FederatedLearning {

    bool public isFull;
    uint public weightCnt;
    uint public totalClients;
    uint[] public weights;
    uint public globalModel;

    event next(string _eveName);
    event complete(string _eveName);  

    constructor() public {
        isFull = false;
        weightCnt = 0;
        totalClients = 0;
    }

    function setClients(uint _num) public {
        totalClients = _num;
    }

    function resetWeights() public {
        weightCnt = 0;
        isFull = false;
    }

    function addWeight(uint _weight) public {
        weights.push(_weight);
        weightCnt = weightCnt + 1;
        if(weightCnt == totalClients){
            isFull=true;
            emit next("Next Round!");
        }
    }

    function updateGBmodel(uint _model) public {
        globalModel = _model;
        resetWeights();
        emit complete("Update Global Model Complete!");
    }

}