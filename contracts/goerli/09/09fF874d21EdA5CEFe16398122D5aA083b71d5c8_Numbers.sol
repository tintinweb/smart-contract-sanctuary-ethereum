// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Numbers {
    uint256 public number1;
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "You are not allowed to do that");
        _;
    }

    function setNumber(uint256 _number) external onlyOwner {
        number1 = _number;
    }

    function getNumber() external view returns (uint256) {
        return number1;
    }
}