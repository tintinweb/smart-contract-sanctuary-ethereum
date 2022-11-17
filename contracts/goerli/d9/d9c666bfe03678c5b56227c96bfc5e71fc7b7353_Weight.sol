/**
 *Submitted for verification at Etherscan.io on 2022-11-17
*/

pragma solidity ^0.8.0;
contract Weight {

    bool public isFull;
    // uint public weightCnt;
    uint public totalClients;
    uint[] public weights;

    event next(string _eveName);
    event complete(string _eveName);  

    constructor() public {
        isFull = false;
        // weightCnt = 0;
        totalClients = 0;
    }

    function setClients(uint _num) public {
        totalClients = _num;
    }

    function resetWeights() public {
        uint weightCnt = weights.length;
        while(weightCnt!=0){
            weights.pop();
            weightCnt--;
        }
    }

    function checkFull() public returns (bool){
        if(weights.length==totalClients){
            isFull=true;
        }else{
            isFull=false;
        }
        return isFull;
    }

    function addWeight(uint _weight) public {
        weights.push(_weight);
        // weightCnt = weightCnt + 1;
        if(weights.length==totalClients){
            isFull=true;
        }
    }

    function notifyNextRound() public { //for clients
        emit next("Next Round!");
    }

    function notifyComplete() public { //for server
        emit complete("Upload Complete!");
    }

}