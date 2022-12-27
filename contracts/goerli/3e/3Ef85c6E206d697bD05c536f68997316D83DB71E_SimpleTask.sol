// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

contract SimpleTask {
    string public message;
    address public owner;
    string public name;
    constructor() {
        owner =  msg.sender;
        name = 'SimpleTask';
    }

    function setOwner(address _newOwner) public {
        owner = _newOwner;
    }

    function getOwner() public view returns (address) {
        return owner;
    }

    function storeMessage(string memory _message) public {
        message = _message;
    }

    function getMessage() public view returns (string memory) {
        return message;
    }
    
    function rename(string memory _newName) public {
        name = _newName;
    }

    function getName() public view returns (string memory) {
        return name;
    }
}