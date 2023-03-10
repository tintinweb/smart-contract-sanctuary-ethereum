//SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract Counter {
    uint256 public counter;
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function add(uint256 x) public {
        counter += x;
    }

    function count() public onlyOwner {
        counter += 1;
    }
}