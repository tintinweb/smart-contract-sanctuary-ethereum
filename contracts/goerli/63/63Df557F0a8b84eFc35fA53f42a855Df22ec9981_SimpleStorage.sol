// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract SimpleStorage {
    uint public variable;

    function setVariable(uint _variable) public {
        variable = _variable;
    }

    function getVariable() public view returns (uint) {
        return variable;
    }
}