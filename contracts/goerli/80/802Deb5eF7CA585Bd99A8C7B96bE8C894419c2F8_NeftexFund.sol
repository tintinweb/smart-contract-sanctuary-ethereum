// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract NeftexFund {

    //create an Operation object for the NeftexFund and specify its types (struct)
    struct Operation {
        address author;
        string subject;
        string narration;
        uint256 objective;
        uint256 durationPeriod;
        uint256 recievedAmount;
        string image;
        address[] funders;
        uint256[] fundings;
    }
    
    //Create a mapping that will point to an Operation
    mapping(uint256 => Operation) public operations;

    //Create a golbal variable and set it to zero  (state)
    uint256 public numOfOperations = 0;

    //Create Operation functions for the NeftexFund
    function createOperation(address _author,
     string memory _subject,
     string memory _narration,
     uint256 _objective,
     uint256 _durationPeriod, 
     string memory _image) public returns (uint256) {
        Operation storage operation = operations[numOfOperations];
        require(operation.durationPeriod < block.timestamp,
        "Sorry!, the duration period isn't over yet.");

        operation.author = _author;
        operation.subject = _subject;
        operation.narration = _narration;
        operation.objective = _objective;
        operation.durationPeriod = _durationPeriod;
        operation.recievedAmount = 0;
        operation.image = _image;

        numOfOperations++;

        return numOfOperations - 1;
     }

    // Create a function fundOperation
    function fundOperation(uint256 _id) public payable {
        uint256 amount = msg.value;

        Operation storage operation = operations[_id];

        operation.funders.push(msg.sender);
        operation.fundings.push(amount);

        (bool sent,) = payable(operation.author).call{value: amount}("");

        if(sent) {
            operation.recievedAmount += amount;
        }
    }

    //Create a function getFunders; the function gets the addresses of the funders.
    function getFunders(uint256 _id) view public returns (address[] memory, 
    uint256[] memory) {
        return (operations[_id].funders, operations[_id].fundings);
    }

    //Create a function getOperationa; the function returns an array of Operations.
    function getOperations() public view returns (Operation[] memory) {
        Operation[] memory allOperations = new Operation[](numOfOperations);

        for (uint k = 0; k < numOfOperations; k++) {
            Operation storage stuff = operations[k];
            
            allOperations[k] = stuff;
        }

        return allOperations;
    
    }


}