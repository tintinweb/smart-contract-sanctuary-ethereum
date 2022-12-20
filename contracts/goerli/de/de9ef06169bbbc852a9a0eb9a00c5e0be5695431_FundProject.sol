/**
 *Submitted for verification at Etherscan.io on 2022-12-20
*/

// SPDX-License-Identifier: MIT

/*
    This contract receives funding from different accounts. Anyone can withdraw the funds.
*/

pragma solidity ^0.8.0;

contract FundProject {
    mapping(address => uint256) public addressToAmountFunded;

    address[] public funders;

    // msg = transaction
    // msg.sender = wallet that made the transaction
    // msg.sender = amaount passed in transaction
    function fund() public payable {
        addressToAmountFunded[msg.sender] += msg.value;
        funders.push(msg.sender);
    }

    function withdraw() public payable {
        
        // Resets map
        for (uint256 funderIndex = 0;funderIndex < funders.length;funderIndex++) {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }

        // Resets funders array
        funders = new address[](0);

        // this = the contract
        // all contracts have a balance
        payable(msg.sender).transfer(address(this).balance);
    }
}