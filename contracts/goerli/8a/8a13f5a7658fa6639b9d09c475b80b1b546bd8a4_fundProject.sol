/**
 *Submitted for verification at Etherscan.io on 2022-12-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

contract fundProject {
    mapping(address => uint256) public addressToAmountFunded;
    address[] public funders;

    address public _owner;
    uint256 maxFund = 10e18;
    uint256 balance = 0;

    constructor() {
        _owner = msg.sender;
    }

    function fund() public payable {
        balance += msg.value;
        require(balance <= maxFund);
        addressToAmountFunded[msg.sender] += msg.value;
        funders.push(msg.sender);
    }

    modifier onlyOwner {
        require(msg.sender == _owner);
        _;
    }
    function getBalance() public view returns(uint256) {
        return balance;
    }
    
    function withdraw() public onlyOwner {
        for (uint256 funderIndex=0; funderIndex < funders.length; funderIndex++){
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }
        funders = new address[](0);
        (bool callSuccess, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess, "Call failed");
    }

    fallback() external payable {
        fund();
    }

    receive() external payable {
        fund();
    }
}