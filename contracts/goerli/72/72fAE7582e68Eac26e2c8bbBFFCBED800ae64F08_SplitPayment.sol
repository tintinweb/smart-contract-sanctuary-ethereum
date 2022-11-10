// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.8;

contract SplitPayment {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    function send(address payable[] memory to, uint256[] memory amount)
        public
        payable
    {
        require(
            to.length == amount.length,
            "to and amount arrays must have same length"
        );
        for (uint256 i = 0; i < to.length; i++) {
            to[i].transfer(amount[i]);
        }
    }
}