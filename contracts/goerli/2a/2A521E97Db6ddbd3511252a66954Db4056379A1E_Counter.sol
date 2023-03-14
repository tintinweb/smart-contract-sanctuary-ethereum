// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Counter {

    uint256 public value;

    address _owner;

    constructor () {
        _owner = msg.sender;
    }

    function add(uint256 x) external {
        value += x;
    }

    function count() public view onlyOwner returns (uint256) {
        return value;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Caller is not the owner");
        _;
    }

}