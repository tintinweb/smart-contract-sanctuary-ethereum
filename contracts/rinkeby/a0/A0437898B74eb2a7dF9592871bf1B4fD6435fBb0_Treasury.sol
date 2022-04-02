//SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.7 <0.9.0;

contract Treasury {
    address public parentContract;
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    function setParentContract(address _parentContract) public {
        require(msg.sender == owner, "Can only be called by contract owner!");
        parentContract = _parentContract;
    }
}