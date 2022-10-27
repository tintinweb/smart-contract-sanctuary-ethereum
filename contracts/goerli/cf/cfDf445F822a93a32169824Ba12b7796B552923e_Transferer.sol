// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

contract Transferer {
    address owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "not owner");
        _;
    }

    function transfer(address receiver) public onlyOwner {
        payable(receiver).transfer(address(this).balance);
    }
}