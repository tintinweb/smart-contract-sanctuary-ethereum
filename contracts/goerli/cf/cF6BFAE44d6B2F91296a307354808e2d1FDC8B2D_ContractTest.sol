/**
 *Submitted for verification at Etherscan.io on 2022-12-24
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

contract ContractTest {
    string public name = "Julio";
    address owner;

    event NameSet(string message1);
    event NameGet(string message2);

    constructor() {
        owner = msg.sender;
    }

    function setName(string memory _name) external onlyOwner {
        name = _name;
        emit NameSet("Name has been set!");
    }

    function getName() external onlyOwner returns (string memory) {
        emit NameGet("Name has been gotten!");
        return name;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
}