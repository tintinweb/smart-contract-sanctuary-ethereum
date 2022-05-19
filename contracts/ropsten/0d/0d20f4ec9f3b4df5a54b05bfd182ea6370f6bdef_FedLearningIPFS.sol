/**
 *Submitted for verification at Etherscan.io on 2022-05-18
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

contract FedLearningIPFS {

    address public owner;
    
    string baseModelHash;
    string config;
    string[] localModelHashes;
    string globalModelHash;
    

    mapping(address => bool) workers;
    uint8 public numWorkers;
    address[] public workerAddresses;

    mapping(address => bool) providers;
    uint8 public numProviders;
    address[] public providerAddresses;

    uint8 numLocalModelsRequired;
    uint8 numRounds;
    uint8 currentRound;

    constructor() {
        owner = msg.sender;

        workers[msg.sender] = true;
        workerAddresses.push(msg.sender);
        numWorkers = 1;
    }

    event startTrainingEvent(uint8 numRounds, uint8 numLocalModelsRequired, string baseModelHash, string config);
    event localModelSentEvent(address client);
    event gotEnoughLocalModelsEvent();
    event globalModelUpdatedEvent(string globalModelHash);
    event finishTrainingEvent(string globalModelHash);

    modifier isWorker(address address_) {
        require(workers[address_], "Need to be a worker to perform this function call!");
        _;
    }

    function addWorker(address workerAddress_) public {
        require(msg.sender == owner, "Need to be the owner to perform this function call!");
        require(!workers[workerAddress_], "Already a worker");
        workers[workerAddress_] = true;
        workerAddresses.push(workerAddress_);
        numWorkers++;
    }

    function registerProvider() public {
        require(!providers[msg.sender], "Already a provider");
        providers[msg.sender] = true;
        providerAddresses.push(msg.sender);
        numProviders++;
    }

    function startTraining(uint8 numRounds_, uint8 numLocalModelsRequired_, string memory baseModelHash_, string memory config_) public {
        numRounds = numRounds_;
        currentRound = 0;

        numLocalModelsRequired = numLocalModelsRequired_;
        
        baseModelHash = baseModelHash_;
        config = config_;
        
        emit startTrainingEvent(numRounds, numLocalModelsRequired, baseModelHash, config);
    }

    function sendLocalModelHash(string memory modelHash_) public {
        localModelHashes.push(modelHash_);
        emit localModelSentEvent(msg.sender);

        if (localModelHashes.length >= numLocalModelsRequired) {
            emit gotEnoughLocalModelsEvent();
        }
    }

    function getLocalModelHashes() public view isWorker(msg.sender) returns(string[] memory)  {
        return localModelHashes;
    }

    function sendGlobalModelHash(string memory globalModelHash_) public isWorker(msg.sender) {
        globalModelHash = globalModelHash_;
        currentRound++;
        if (currentRound == numRounds) {
            emit finishTrainingEvent(globalModelHash);
        } else {
            emit globalModelUpdatedEvent(globalModelHash);
        }
        delete localModelHashes;
    }

    function getGlobalModelHash() public view returns(string memory) {
        return globalModelHash;
    }

}