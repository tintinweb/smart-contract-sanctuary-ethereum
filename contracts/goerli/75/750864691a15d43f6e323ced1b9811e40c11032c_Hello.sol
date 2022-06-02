/**
 *Submitted for verification at Etherscan.io on 2022-06-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

contract Hello {
    address owner;
    string currentName;
    string constant HELLO = "Hello, ";
    constructor() {
        owner = msg.sender;
    }
    modifier onlyOwner() {
        require(msg.sender == owner, "Error: Not enough permisison to setName");
        _;
    }
    function setName(string calldata _name) external onlyOwner{
        currentName = _name;
    }
    function getName() external view returns (string memory){
        return currentName;
    }
    function hello() external view returns (string memory) {
        return string.concat(HELLO, currentName);
    }
}