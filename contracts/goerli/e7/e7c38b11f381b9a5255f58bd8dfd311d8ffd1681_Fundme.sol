/**
 *Submitted for verification at Etherscan.io on 2022-11-21
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

error pricenotmet();

contract Fundme {
    address[] public funders;
    mapping(address => uint256) public amountfunded;
    // 1 funtions to fund
    // 2 withdraw  functions
    uint256 price = 1 ether;
    event funded(
        address indexed funder,
        uint amountFund
    );



    function fund() public payable {
        if (msg.value != price) {
            revert pricenotmet();
        }
        amountfunded[msg.sender] += msg.value;
        funders.push(msg.sender);
        emit funded(msg.sender,msg.value);
    }

    function withdraw() public payable {
        for (
            uint funderindex = 0;
            funderindex >= funders.length;
            funderindex++
        ) {
            address funder = funders[funderindex];
            amountfunded[funder] = 0;
            funders = new address[](0);
        }
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success, "transferfailed");
    }
}