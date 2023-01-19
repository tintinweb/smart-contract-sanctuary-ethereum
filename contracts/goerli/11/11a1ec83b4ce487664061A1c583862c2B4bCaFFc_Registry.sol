// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract Registry {
    // use to create the unique index 
    uint counter = 0;

    struct ModelRequest {
        uint id;
        string name;
        uint numberAgentRequired;
    }

    mapping(uint => ModelRequest) public idToRequest;

    ModelRequest[] public requests;
    event NewRequest(ModelRequest request);

    ////////
    // For the response given by the Knowledge Manager
    struct ModelResponse {
        uint forId;
        bytes32 hashOfModel;
    }

    // For now only one possible response for one request
    mapping(uint => ModelResponse) public idToResponse;

    event NewResponse(ModelResponse response);
    

    function requestModel(
        string memory _name,
        uint _numberAgentRequired
    ) public {
        //bytes20 newId = bytes20(keccak256(abi.encode(_name,counter,block.timestamp)));
        // Let's use simple id first
        uint newId = counter;
        ModelRequest memory modelRequested = ModelRequest(
            newId,
            _name,
            _numberAgentRequired
        );
        requests.push(modelRequested);
        idToRequest[newId] = modelRequested;
        counter++;
        emit NewRequest(modelRequested);
    }

    function answerRequest(uint requestId, bytes32 hashOfModel) public {
        ModelResponse memory responseFromServer = ModelResponse(
            requestId,
            hashOfModel
        );
        idToResponse[requestId] = responseFromServer;
        emit NewResponse(responseFromServer);
    }
}