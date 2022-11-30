// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Registry {

    struct ModelRequest {
        string name;
        uint numberAgentRequired;
    }

    ModelRequest[] public requests;
    event NewRequest(ModelRequest request);

    function requestModel(string memory _name, uint _numberAgentRequired) public {
        ModelRequest memory modelRequested = ModelRequest(_name,_numberAgentRequired);
        requests.push(modelRequested);
        emit NewRequest(modelRequested);
    }
}