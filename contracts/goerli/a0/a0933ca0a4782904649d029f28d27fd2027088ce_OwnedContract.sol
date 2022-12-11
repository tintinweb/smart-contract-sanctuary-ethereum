// SPDX-License-Identifer: Unlicensed
pragma solidity ^0.8.0;

contract OwnedContract {
    address private owner;

    modifier onlyOwner {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function getOwner() public view returns (address) {
        return owner;
    }

    function setOwner(address newOwner) public virtual onlyOwner {
        owner = newOwner;
    } 
}