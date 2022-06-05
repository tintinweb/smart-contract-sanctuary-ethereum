//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

contract Verify {
    string private greeting;
    address owner;
    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "Not the owner :D");
        _;
    }

    function setOwnerShip(address _owner) public onlyOwner {
        owner = _owner;
    }
}