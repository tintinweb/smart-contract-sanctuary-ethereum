/**
 *Submitted for verification at Etherscan.io on 2023-01-27
*/

// SPDX-License-Identifier: MIT

/*
    This contract recevives funding from different accounts. Only the contract owner can withdraw these funds.
*/

pragma solidity ^0.8.0;

contract FundProjectForOwner {
    address public owner;

    mapping(address => uint256) public addressToAmountFunded;

    address[] public funders;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "You are not the owner of this contract!");
        _;
    }

    function fund() public payable {
        addressToAmountFunded[msg.sender] += msg.value;
        funders.push(msg.sender);
    }

    function withdraw() public payable onlyOwner {
        // Resets map
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }

        // Resets funders array
        funders = new address[](0);

        payable(msg.sender).transfer(address(this).balance);
    }
}