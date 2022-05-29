// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

contract DummyTargetContract {
    mapping(uint256 => uint256) public executions;
    address governorAddress;

    constructor(address governorAddress_) {
        governorAddress = governorAddress_;
    }

    function getExecution(uint256 executionId) public view returns (uint256) {
        return executions[executionId];
    }

    function proposalExecute(uint256 executionId, uint256 value) public {
        require(msg.sender == governorAddress);
        executions[executionId] = value;
    }
}