// SPDX-License-Identifier: NONE
pragma solidity ^0.8.18;

contract TestChangeState {
bool public contractStatus;
address[] public connectedAddresses;
address public owner;
constructor() {
    contractStatus = false;
    owner = msg.sender;
}

function changeContractStatus() public {
    require(msg.sender == owner, "Only owner can call this function.");
    contractStatus = !contractStatus;
    connectedAddresses.push(msg.sender); // Add the address of the caller to the array
}

function getConnectedAddresses() public view returns (address[] memory) {
    require(msg.sender == owner, "Only owner can call this function.");
    return connectedAddresses;
}
}