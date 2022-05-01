// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Bounty {
    address public owner;
    uint256 public bounty_amount;

    constructor() public {
        owner = msg.sender;
    }

    function fund() public payable {
        bounty_amount = bounty_amount + msg.value;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function withdraw() public payable onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}