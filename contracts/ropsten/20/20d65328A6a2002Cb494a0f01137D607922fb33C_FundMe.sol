// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

//import SafeMath;

contract FundMe {
    uint256 minAmount = 1000000000;

    mapping(address => uint256) public addressToAmounyFunded;
    address[] public funders;
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    function fund() public payable {
        require(msg.value >= minAmount, "You need to spend more ETH");
        addressToAmounyFunded[msg.sender] += msg.value;
        funders.push(msg.sender);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not an owner");
        _;
    }

    function withdraw() public payable onlyOwner {
        msg.sender.transfer(address(this).balance);
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            addressToAmounyFunded[funder] = 0;
        }
        funders = new address[](0);
    }
}