// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

contract Counter {
    event Transfer(address indexed from, address indexed to, uint256 amount);

    uint256 public number;
    address public owner;

    constructor(uint256 i) {
        owner = msg.sender;
        number = i;
    }

    function set(uint256 newNumber) public {
        number = newNumber;
    }

    function t() public {
        emit Transfer(msg.sender, address(1337), 1337);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "only owner can call");
        _;
    }

    function increment() public onlyOwner {
        number++;
    }
}