/**
 *Submitted for verification at Etherscan.io on 2022-05-16
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;


contract KarafuruReserved {

    uint256 depositAmount = 0.175 ether; // 70% of DA bottom price
    address owner;

    constructor() {
        owner = msg.sender;
    }

    mapping(address => uint256) public addressDeposited;
    address[] public funders;

    modifier onlyOwner {
        require(msg.sender == owner, "Only owner can access");
        _;
    }
  
    function deposit() public payable {
        require(msg.value >= depositAmount, "Not enough ETH for deposit");
        addressDeposited[msg.sender] += msg.value;
        funders.push(msg.sender);
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    // Refund if unforeseen event occurs
    function refund() public onlyOwner {
        for (uint256 funderIndex = 0; funderIndex < funders.length; funderIndex++) {
            address funder = funders[funderIndex];
            payable(funder).transfer(addressDeposited[funder]);
            addressDeposited[funder] = 0;
        }
    }

}